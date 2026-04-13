import Foundation
  import Combine
  import Supabase
                                                            
  final class AppState: ObservableObject {
      @Published var isAuthenticated = false
      @Published var isGuest = false
      @Published var currentUserId: UUID?
      @Published var profile: Profile?
      @Published var isLoading = true
      @Published var needsProfileOnboarding = false
      @Published var needsChurchOnboarding = false

      // Church cache — loaded once on app init, used throughout the app
      @Published var approvedChurches: [ChurchSubmission] = []
      private var churchesBySlug: [String: ChurchSubmission] = [:]

      init() {
          Task { await checkSession() }
          Task { await listenForAuthChanges() }
          Task { await loadApprovedChurches() }
      }
  
      func checkSession() async {
          await MainActor.run { isLoading = true }
          do {
              let session = try await SupabaseService.shared.client.auth.session
              await MainActor.run {
                  currentUserId = session.user.id
                  isAuthenticated = true
              }
              await loadProfile()
          } catch {
              await MainActor.run {
                  isAuthenticated = false
                  currentUserId = nil
                  profile = nil
              }
          }
          await MainActor.run { isLoading = false }
      }

      func loadProfile() async {
          guard let userId = await MainActor.run(body: { currentUserId }) else { return }
          print("[AppState] loadProfile: fetching profile for \(userId)")
          do {
              guard let p = try await SupabaseService.shared.getProfile(userId: userId) else {
                  print("[AppState] loadProfile: no profile row found for \(userId)")
                  return
              }
              await MainActor.run { profile = p }
              print("[AppState] loadProfile: role=\(p.role ?? "nil")")
              await checkProfileOnboarding()
          } catch {
              print("[AppState] loadProfile error: \(error)")
          }
      }

      @MainActor
      private func checkProfileOnboarding() {
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
              needsChurchOnboarding = !UserDefaults.standard.bool(forKey: key)
              print("[AppState] → church onboarding needed: \(needsChurchOnboarding)")
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
          try? await SupabaseService.shared.signOut()
          await MainActor.run {
              isAuthenticated = false
              isGuest = false
              currentUserId = nil
              profile = nil
          }
      }

      func continueAsGuest() {
          isGuest = true
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

      /// Convert a ChurchSubmission (from Supabase) to a Church struct (for view display)
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
              isLive: submission.isLive
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
          for await (event, session) in await SupabaseService.shared.client.auth.authStateChanges {
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
                      isGuest = false
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


