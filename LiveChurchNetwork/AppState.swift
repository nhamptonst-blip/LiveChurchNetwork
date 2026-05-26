import Foundation
  import Combine
  import Supabase
                                                            
  final class AppState: ObservableObject {
      @Published var isAuthenticated = false
      @Published var currentUserId: UUID?
      @Published var profile: Profile?
      @Published var isLoading = true
      @Published var needsProfileOnboarding = false
      @Published var needsChurchOnboarding = false

      // Church cache — loaded once on app init, used throughout the app
      @Published var approvedChurches: [ChurchSubmission] = []
      private var churchesBySlug: [String: ChurchSubmission] = [:]

      // Trust & safety filters — cached so feed/profile/etc. queries can
      // strip blocked authors and hidden posts without a roundtrip per
      // render. Refreshed on sign-in and after the viewer blocks/hides.
      @Published var blockedUserIds: Set<UUID> = []
      @Published var hiddenPostIds: Set<UUID>  = []

      init() {
          Task { await listenForAuthChanges() }
          Task { await loadApprovedChurches() }
      }

      /// Pull the current user's block + hide lists into memory. Called once
      /// after sign-in and from any view that mutates safety state.
      func refreshSafetyFilters() async {
          guard let uid = currentUserId else {
              await MainActor.run {
                  blockedUserIds = []
                  hiddenPostIds  = []
              }
              return
          }
          do {
              let (blocks, hides) = try await SupabaseService.shared.getSafetyFilters(userId: uid)
              await MainActor.run {
                  blockedUserIds = blocks
                  hiddenPostIds  = hides
              }
          } catch {
              print("[AppState] safety filters refresh failed: \(error.localizedDescription)")
          }
      }
  
      func checkSession() async {
          await MainActor.run { isLoading = true }
          do {
              let session = try await SupabaseService.shared.client.auth.session
              await MainActor.run {
                  currentUserId = session.user.id
                  isAuthenticated = true
                  print("[AppState.checkSession] Set currentUserId=\(session.user.id)")
              }
              await loadProfile()
              // Re-submit any cached APNs token now that we know who the
              // signed-in user is, and re-register if they previously granted
              // notification permission. No-op if token isn't cached yet.
              await PushService.shared.resubmitCachedToken(userId: session.user.id)
              await PushService.shared.registerIfPreviouslyAuthorized()
          } catch {
              await MainActor.run {
                  isAuthenticated = false
                  currentUserId = nil
                  profile = nil
                  print("[AppState.checkSession] Session error: \(error)")
              }
          }
          await MainActor.run { isLoading = false }
      }

      func loadProfile() async {
          guard let userId = currentUserId else { return }
          print("[AppState] loadProfile: fetching profile for \(userId)")
          do {
              guard let p = try await SupabaseService.shared.getProfile(userId: userId) else {
                  print("[AppState] loadProfile: no profile row found for \(userId)")
                  return
              }
              await MainActor.run { profile = p }
              print("[AppState] loadProfile: role=\(p.role ?? "nil")")

              await checkProfileOnboarding()
              await refreshSafetyFilters()
          } catch {
              print("[AppState] loadProfile error: \(error)")
          }
      }

      @MainActor
      private func checkProfileOnboarding() async {
          guard let userId = currentUserId else { return }
          // Guard on role explicitly — never fall back to worshipper if role is unknown
          guard let p = profile, let role = p.role, !role.isEmpty else {
              print("[AppState] checkProfileOnboarding: role unavailable — skipping routing until profile loads")
              return
          }
          print("[AppState] checkProfileOnboarding: userId=\(userId), role=\(role)")
          switch role {
          case "church_admin":
              needsProfileOnboarding = false
              let key = "churchOnboarding_complete_\(userId)"
              if UserDefaults.standard.bool(forKey: key) {
                  needsChurchOnboarding = false
              } else {
                  // No local flag — but the church may already exist on the
                  // server (signed in from a fresh install / new device). If
                  // a church_submissions row exists with at least a name,
                  // honor that as "already onboarded" and persist the flag
                  // so we don't ask again on this device.
                  let alreadyExists = await churchSubmissionExists(for: userId)
                  if alreadyExists {
                      UserDefaults.standard.set(true, forKey: key)
                      needsChurchOnboarding = false
                      print("[AppState] → existing church_submissions detected; skipping onboarding")
                  } else {
                      needsChurchOnboarding = true
                      print("[AppState] → no church_submissions row; onboarding needed")
                  }
              }
          case "worshipper":
              needsChurchOnboarding = false
              let key = "profileOnboarding_complete_\(userId)"
              needsProfileOnboarding = !UserDefaults.standard.bool(forKey: key)
              print("[AppState] → profile onboarding needed: \(needsProfileOnboarding)")
          default:
              needsProfileOnboarding = false
              needsChurchOnboarding = false
              print("[AppState] → role '\(role)' requires no onboarding")
          }
      }

      /// Cheap probe — does the signed-in church admin already have a
      /// `church_submissions` row with a non-empty `church_name`? Returns
      /// false on any error so we err toward showing onboarding rather
      /// than skipping it incorrectly.
      private func churchSubmissionExists(for userId: UUID) async -> Bool {
          do {
              let row = try await SupabaseService.shared.getChurchSubmission(userId: userId)
              return (row?.churchName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
          } catch {
              print("[AppState] churchSubmissionExists probe failed: \(error.localizedDescription)")
              return false
          }
      }

      @MainActor
      func completeProfileOnboarding() {
          guard let userId = currentUserId else { return }
          UserDefaults.standard.set(true, forKey: "profileOnboarding_complete_\(userId)")
          needsProfileOnboarding = false
      }

      @MainActor
      func completeChurchOnboarding() {
          guard let userId = currentUserId else { return }
          UserDefaults.standard.set(true, forKey: "churchOnboarding_complete_\(userId)")
          needsChurchOnboarding = false
      }

      func signOut() async {
          // Drop the APNs token row first so the user stops getting pushes
          // for an account they're no longer signed into.
          if let uid = currentUserId {
              await PushService.shared.removeCurrentToken(userId: uid)
          }
          try? await SupabaseService.shared.signOut()
          await MainActor.run {
              isAuthenticated = false
              currentUserId = nil
              profile = nil
          }
      }

      // MARK: - Church Cache

      private func loadApprovedChurches() async {
          do {
              let churches = try await SupabaseService.shared.getApprovedChurches()
              await MainActor.run {
                  self.approvedChurches = churches
                  // Build slug → church lookup map
                  var map: [String: ChurchSubmission] = [:]
                  for church in churches {
                      let slug = (church.churchName ?? "").lowercased().replacingOccurrences(of: " ", with: "-")
                      map[slug] = church
                  }
                  self.churchesBySlug = map
              }
          } catch {
              print("[AppState] loadApprovedChurches error: \(error)")
          }
      }

      func church(bySlug slug: String) -> ChurchSubmission? {
          return churchesBySlug[slug]
      }

      func church(byName name: String) -> ChurchSubmission? {
          return approvedChurches.first {
              ($0.churchName ?? "").localizedCaseInsensitiveCompare(name) == .orderedSame
          }
      }

      func churchSlug(byName name: String) -> String? {
          guard let church = church(byName: name) else { return nil }
          return (church.churchName ?? "").lowercased().replacingOccurrences(of: " ", with: "-")
      }

      /// Convert a ChurchSubmission (from Supabase) to a Church struct (for view display).
      /// `isLive` is derived: it's true if the admin manually toggled Go Live OR
      /// the church is currently inside a scheduled service window (timezone-aware).
      /// Source of truth: LiveChurchEvaluator.isLiveNow.
      func toChurch(_ submission: ChurchSubmission) -> Church {
          let slug = (submission.churchName ?? "").lowercased().replacingOccurrences(of: " ", with: "-")
          return Church(
              name: submission.churchName ?? "",
              slug: slug,
              image: submission.avatarUrl ?? "", // Use Supabase Storage URL if available
              denomination: submission.denomination ?? "",
              permalink: "",
              phone: submission.phone ?? "",
              website: submission.website ?? "",
              serviceTimes: submission.serviceTimes ?? "",
              about: submission.about ?? "",
              isLive: LiveChurchEvaluator.isLiveNow(submission)
          )
      }

      /// Get all approved churches as Church structs (for display)
      func allChurchesForDisplay() -> [Church] {
          return approvedChurches.map { toChurch($0) }
      }

      /// Get churches by slug set (for profile follow lists, etc)
      func churches(bySlugs slugs: Set<String>) -> [Church] {
          return approvedChurches
              .filter { church in
                  let slug = (church.churchName ?? "").lowercased().replacingOccurrences(of: " ", with: "-")
                  return slugs.contains(slug)
              }
              .map { toChurch($0) }
      }
                                                            
      private func listenForAuthChanges() async {
          for await (event, session) in SupabaseService.shared.client.auth.authStateChanges {
              // Capture whether we need to load a profile before releasing the splash screen
              let needsProfileLoad: Bool = await MainActor.run {
                  switch event {
                  case .signedIn:
                      if let session {
                          print("[AppState] auth event: signedIn userId=\(session.user.id)")
                          currentUserId = session.user.id
                          isAuthenticated = true
                          isLoading = true   // hold splash until profile + onboarding routing ready
                          return true
                      }
                      isLoading = false
                      return false
                  case .signedOut:
                      print("[AppState] auth event: signedOut")
                      isAuthenticated = false
                      currentUserId = nil
                      profile = nil
                      needsProfileOnboarding = false
                      needsChurchOnboarding = false
                      isLoading = false
                      return false
                  default:
                      isLoading = false
                      return false
                  }
              }
              if needsProfileLoad {
                  await loadProfile()
                  await MainActor.run { isLoading = false }
              }
          }
      }
  }


