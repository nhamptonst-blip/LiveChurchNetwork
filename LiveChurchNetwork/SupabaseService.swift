import Foundation
 import Supabase
                                                                                                                                                                                
 // MARK: - Insert / update payload structs
                                                           
 private struct ProfileInsert: Encodable {
     let id: String
     let full_name: String
     let role: String
     var bio: String?
     var city: String?
     var denomination: String?
 }

 private struct ChurchSubmissionInsert: Encodable {
     let user_id: String
     let church_name: String
 }

 private struct LiveUpdate: Encodable {
     let is_live: Bool
 }
                                                           
 private struct ChurchProfileUpdate: Encodable {
     let church_name: String
     let denomination: String
     let phone: String
     let website: String
     let service_times: String
     let about: String
 }

 /// Full set of contact + outreach fields editable from the iOS Edit Profile
 /// sheet. Sent as a partial UPDATE so any nil field is left untouched.
 private struct ChurchDetailsUpdate: Encodable {
     var contact_email: String?
     var donation_url: String?
     var livestream_url: String?
     var address_line: String?
     var city: String?
     var state: String?
     var postal_code: String?
     var country: String?
     var pastor_name: String?
     var what_to_expect: String?
     var ministries: String?
     var facebook_url: String?
     var instagram_url: String?
     var tiktok_url: String?
     var x_url: String?
     var youtube_url: String?
 }

 /// Richer payload for the structured-schedule editors. Writes both the new
 /// JSONB columns and the legacy text columns (auto-derived summary) so iOS
 /// stays in sync with the web-app behavior described in
 /// `supabase/migrations/20260507_structured_schedule.sql`.
 private struct ChurchScheduleUpdate: Encodable {
     let service_times: String?
     let service_times_json: [ServiceTime]?
     let office_hours: String?
     let office_hours_json: OfficeHours?
     let livestream_schedule_json: LivestreamSchedule?
 }

 private struct ChurchAvatarUpdate: Encodable { let avatar_url: String }
 private struct ChurchCoverUpdate: Encodable { let cover_url: String }
 private struct ChurchNotifyFollowersUpdate: Encodable { let notify_followers: Bool }
  
 private struct SavedChurchInsert: Encodable {
     let user_id: String
     let church_slug: String
 }
  
 private struct PostInsert: Encodable {
     let author_id: String
     let author_name: String
     let author_type: String
     let content: String?
     let photo_url: String?
     let video_url: String?
     let post_type: String
     let is_important: Bool
     let is_pinned: Bool
     let send_notification: Bool
     let highlight_in_feed: Bool
 }

 private struct EventInsert: Encodable {
     let author_id: String
     let author_name: String
     let title: String
     let description: String?
     let event_date: String
     let location: String?
 }

 private struct FollowInsert: Encodable {
     let follower_id: String
     let following_id: String
     let following_type: String
 }
  
 private struct LikeInsert: Encodable {
     let user_id: String
     let post_id: String
 }

 private struct LikeCountUpdate: Encodable {
     let like_count: Int
 }

 // prayer_responses table
 private struct PrayerResponseInsert: Encodable {
     let user_id: String
     let prayer_post_id: String
 }
 private struct PrayerResponseRow: Decodable {
     let prayer_post_id: String
 }
 private struct PrayerCountUpdate: Encodable {
     let prayer_count: Int
 }

 // event_rsvps table
 private struct EventRsvpInsert: Encodable {
     let event_id: String
     let user_id: String
 }
 private struct EventRsvpRow: Decodable {
     let event_id: String
 }

 // device_tokens table — APNs push registration
 private struct DeviceTokenUpsert: Encodable {
     let user_id: String
     let token: String
     let platform: String
     let app_version: String?
     let device_model: String?
     let os_version: String?
 }

 // church_inquiries table
 // Required columns: id uuid pk default, member_id uuid, member_name text,
 //   church_slug text, church_name text, type text, subject text, body text,
 //   status text default 'new', created_at timestamptz default now()
 private struct ChurchInquiryInsert: Encodable {
     let member_id: String
     let member_name: String
     let church_slug: String
     let church_name: String
     let type: String
     let subject: String
     let body: String
 }

 private struct InquiryStatusUpdate: Encodable {
     let status: String
 }

 private struct NotificationReadUpdate: Encodable {
     let is_read: Bool
 }

// NOTE: Requires columns in profiles table:
//   activity_visibility text default 'public'
//   followers_visibility text default 'public'
//   following_visibility text default 'public'
//   churches_visibility  text default 'public'
private struct PrivacySettingsUpdate: Encodable {
    let activity_visibility:  String
    let followers_visibility: String
    let following_visibility: String
    let churches_visibility:  String
}

// NOTE: Requires 'bio text', 'photo_url text', 'cover_url text', 'home_church_slug text',
// 'home_church_name text', 'languages text' columns in profiles table.
private struct ProfileUpdate: Encodable {
    let full_name: String
    let city: String
    let denomination: String
    let bio: String
    let home_church_slug: String?
    let home_church_name: String?
    let languages: String?
}

private struct ProfilePhotoUpdate: Encodable {
    let photo_url: String
}

private struct ProfileCoverUpdate: Encodable {
    let cover_url: String
}

 // MARK: - Service

 class SupabaseService {
     static let shared = SupabaseService()
                                                                                                                                                                                
     // NOTE: Anon (publishable) key is safe to ship in the binary — it gates
     // public reads only and all writes are RLS-enforced. Move to xcconfig
     // before public launch for hygiene; not required for functionality.
     let client = SupabaseClient(
         supabaseURL: URL(string: "https://hjckwtjzvuacpckqsasa.supabase.co")!,
         supabaseKey: "sb_publishable_7Ws54QaJ7y_7GHN3SG8vqA_Giuf6OQ8"
     )
                                                                                                                                                                                
     // MARK: Auth

     func signIn(email: String, password: String) async throws {
         try await client.auth.signIn(email: email, password: password)
     }

     /// Hard-deletes the signed-in user's account via the `delete-account`
     /// Edge Function. Required by App Store Guideline 5.1.1(v): users
     /// must be able to delete their account from inside the app.
     ///
     /// The Edge Function reads the caller's JWT, verifies it, then uses
     /// service-role to call auth.admin.deleteUser — which cascades to
     /// every owned row through the existing FK constraints. Storage
     /// objects under `${userId}/` in avatars/covers/posts buckets are
     /// removed first since storage doesn't cascade.
     func deleteCurrentAccount() async throws {
         struct EdgeError: Decodable { let error: String? }
         let session = try await client.auth.session
         var request = URLRequest(
             url: URL(string: "https://hjckwtjzvuacpckqsasa.supabase.co/functions/v1/delete-account")!,
         )
         request.httpMethod = "POST"
         request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
         request.setValue("application/json", forHTTPHeaderField: "Content-Type")
         let (data, response) = try await URLSession.shared.data(for: request)
         guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
             let detail = (try? JSONDecoder().decode(EdgeError.self, from: data))?.error
                 ?? "Couldn't delete account."
             throw NSError(
                 domain: "lcn.deleteAccount",
                 code: (response as? HTTPURLResponse)?.statusCode ?? -1,
                 userInfo: [NSLocalizedDescriptionKey: detail]
             )
         }
         // Auth user is gone server-side; clear the local session too so
         // the app routes back to the sign-in flow.
         try? await client.auth.signOut()
     }

     /// Exchanges Apple's identity token for a Supabase session. The raw
     /// nonce is the same value whose SHA-256 hash was sent to Apple in
     /// the original request — Supabase verifies it matches the hash
     /// embedded in the JWT so we know this token belongs to *this*
     /// authentication attempt.
     func signInWithApple(idToken: String, nonce: String) async throws {
         try await client.auth.signInWithIdToken(
             credentials: OpenIDConnectCredentials(
                 provider: .apple,
                 idToken: idToken,
                 nonce: nonce
             )
         )
     }
  
     func signUp(email: String, password: String, fullName: String, role: String,
                 bio: String? = nil, city: String? = nil, denomination: String? = nil) async throws {
         let response = try await client.auth.signUp(email: email, password: password)
         let userId = response.user.id
         print("[SupabaseService] signUp: userId=\(userId), role=\(role)")
         // Upsert so we overwrite any row created by a Supabase auth trigger
         try await client
             .from("profiles")
             .upsert(ProfileInsert(id: userId.uuidString, full_name: fullName, role: role,
                                   bio: bio, city: city, denomination: denomination))
             .execute()
         // Church admins need a church_submissions row so onboarding can save info
         if role == "church_admin" {
             print("[SupabaseService] signUp: creating church_submission row")
             _ = try? await client
                 .from("church_submissions")
                 .insert(ChurchSubmissionInsert(user_id: userId.uuidString, church_name: fullName))
                 .execute()
         }
     }
                                                                                                                                                                                
     func signOut() async throws {
         try await client.auth.signOut()
     }

     // MARK: Profile
  
     func getProfile(userId: UUID) async throws -> Profile? {
         let profiles: [Profile] = try await client
             .from("profiles")
             .select()
             .eq("id", value: userId.uuidString)
             .execute()
             .value
         return profiles.first
     }

     func getAllProfiles() async throws -> [Profile] {
         return try await client
             .from("profiles")
             .select()
             .execute()
             .value
     }

     func getDiscoverableWorshippers() async throws -> [Profile] {
         return try await client
             .from("profiles")
             .select()
             .eq("role", value: "worshipper")
             .execute()
             .value
     }

     /// Worshippers who follow any of the given church slugs, with privacy
     /// settings respected. Excludes the current user and anyone whose
     /// `activity_visibility` is `'private'`.
     func getDiscoverableWorshippersByChurches(slugs: [String],
                                                excludeUserId: UUID?,
                                                limit: Int = 20) async throws -> [Profile] {
         guard !slugs.isEmpty else { return [] }

         let memberFollows: [Follow] = try await client
             .from("follows")
             .select()
             .in("following_id", values: slugs)
             .eq("following_type", value: "church")
             .execute()
             .value

         let memberIds: [String] = Array(Set(memberFollows.map { $0.followerId.uuidString }))
             .filter { excludeUserId?.uuidString != $0 }

         guard !memberIds.isEmpty else { return [] }

         return try await client
             .from("profiles")
             .select()
             .eq("role", value: "worshipper")
             .neq("activity_visibility", value: "private")
             .in("id", values: memberIds)
             .limit(limit)
             .execute()
             .value
     }

    func getProfiles(ids: [UUID]) async throws -> [Profile] {
        guard !ids.isEmpty else { return [] }
        let idStrings = ids.map { $0.uuidString }
        return try await client
            .from("profiles")
            .select()
            .in("id", values: idStrings)
            .execute()
            .value
    }

    func getFollowers(userId: UUID) async throws -> [Follow] {
        return try await client
            .from("follows")
            .select()
            .eq("following_id", value: userId.uuidString)
            .execute()
            .value
    }

    /// Followers of a church. Distinct from `getFollowers(userId:)` which
    /// queries by user_id and only works for worshippers — churches are
    /// followed by `following_id = <church-slug>` with `following_type = "church"`.
    func getChurchFollowers(slug: String) async throws -> [Follow] {
        return try await client
            .from("follows")
            .select()
            .eq("following_id", value: slug)
            .eq("following_type", value: "church")
            .execute()
            .value
    }

     func updateProfile(userId: UUID,
                        fullName: String,
                        city: String,
                        denomination: String,
                        bio: String,
                        homeChurchSlug: String?,
                        homeChurchName: String?,
                        languages: String? = nil) async throws {
         try await client
             .from("profiles")
             .update(ProfileUpdate(
                 full_name: fullName,
                 city: city,
                 denomination: denomination,
                 bio: bio,
                 home_church_slug: homeChurchSlug,
                 home_church_name: homeChurchName,
                 languages: languages
             ))
             .eq("id", value: userId.uuidString)
             .execute()
     }

     func updatePrivacySettings(userId: UUID,
                                activity: PrivacySetting,
                                followers: PrivacySetting,
                                following: PrivacySetting,
                                churches: PrivacySetting) async throws {
         try await client
             .from("profiles")
             .update(PrivacySettingsUpdate(
                 activity_visibility:  activity.rawValue,
                 followers_visibility: followers.rawValue,
                 following_visibility: following.rawValue,
                 churches_visibility:  churches.rawValue
             ))
             .eq("id", value: userId.uuidString)
             .execute()
     }

     // MARK: Profile image upload
     // Requires Supabase Storage buckets: "avatars" (public) and "covers" (public)

     func uploadProfileImage(userId: UUID, data: Data, bucket: String) async throws -> String {
         let ext = "jpg"
         let path = "\(userId.uuidString).\(ext)"
         try await client.storage
             .from(bucket)
             .upload(path, data: data,
                     options: FileOptions(contentType: "image/jpeg", upsert: true))
         let url = try client.storage.from(bucket).getPublicURL(path: path)
         return url.absoluteString
     }

     func updateProfilePhotoUrl(userId: UUID, photoUrl: String) async throws {
         try await client
             .from("profiles")
             .update(ProfilePhotoUpdate(photo_url: photoUrl))
             .eq("id", value: userId.uuidString)
             .execute()
     }

     func updateProfileCoverUrl(userId: UUID, coverUrl: String) async throws {
         try await client
             .from("profiles")
             .update(ProfileCoverUpdate(cover_url: coverUrl))
             .eq("id", value: userId.uuidString)
             .execute()
     }

     /// Church logo → `church_submissions.avatar_url` (the per-church field the
     /// Discover directory reads). Targets a specific submission by id, never
     /// by user_id (the bulk-import account owns hundreds of churches).
     func updateChurchAvatarUrl(submissionId: UUID, avatarUrl: String) async throws {
         try await client
             .from("church_submissions")
             .update(ChurchAvatarUpdate(avatar_url: avatarUrl))
             .eq("id", value: submissionId.uuidString)
             .execute()
     }

     func updateChurchCoverUrl(submissionId: UUID, coverUrl: String) async throws {
         try await client
             .from("church_submissions")
             .update(ChurchCoverUpdate(cover_url: coverUrl))
             .eq("id", value: submissionId.uuidString)
             .execute()
     }

     /// Persist the admin's preference for notifying followers when the
     /// church goes live. Enforcement (actually sending the notification)
     /// lives in the DB notification trigger and is out of scope here.
     func updateChurchNotifyFollowers(submissionId: UUID, notifyFollowers: Bool) async throws {
         try await client
             .from("church_submissions")
             .update(ChurchNotifyFollowersUpdate(notify_followers: notifyFollowers))
             .eq("id", value: submissionId.uuidString)
             .execute()
     }

     // MARK: Saved churches

     func getSavedChurches(userId: UUID) async throws -> [SavedChurch] {
         return try await client
             .from("saved_churches")
             .select()
             .eq("user_id", value: userId.uuidString)
             .execute()
             .value
     }
                                                                                                                                                                                
     func saveChurch(userId: UUID, churchSlug: String) async throws {
         try await client
             .from("saved_churches")
             .insert(SavedChurchInsert(user_id: userId.uuidString, church_slug: churchSlug))
             .execute()
     }
                                                                                                                                                                                
     func unsaveChurch(userId: UUID, churchSlug: String) async throws {
         try await client
             .from("saved_churches")
             .delete()
             .eq("user_id", value: userId.uuidString)
             .eq("church_slug", value: churchSlug)
             .execute()
     }

     // MARK: Church admin
  
     func getChurchSubmission(userId: UUID) async throws -> ChurchSubmission? {
         let rows: [ChurchSubmission] = try await client
             .from("church_submissions")
             .select()
             .eq("user_id", value: userId.uuidString)
             .execute()
             .value
         return rows.first
     }

     /// Fetches the church submission for this user, creating the row if it doesn't exist yet.
     /// Handles accounts created before the signup fix that seeds the row automatically.
     func getOrCreateChurchSubmission(userId: UUID, churchName: String) async throws -> ChurchSubmission {
         if let existing = try? await getChurchSubmission(userId: userId) {
             return existing
         }
         print("[SupabaseService] getOrCreateChurchSubmission: no row found, creating one")
         try await client
             .from("church_submissions")
             .insert(ChurchSubmissionInsert(user_id: userId.uuidString, church_name: churchName))
             .execute()
         guard let created = try? await getChurchSubmission(userId: userId) else {
             throw NSError(domain: "LCN", code: 1001,
                           userInfo: [NSLocalizedDescriptionKey: "Could not create church submission row"])
         }
         return created
     }

     func updateLiveStatus(submissionId: UUID, isLive: Bool) async throws {
         try await client
             .from("church_submissions")
             .update(LiveUpdate(is_live: isLive))
             .eq("id", value: submissionId.uuidString)
             .execute()
     }
  
     func updateChurchProfile(submissionId: UUID, churchName: String, denomination: String,
                               phone: String, website: String, serviceTimes: String, about: String) async throws {
         try await client
             .from("church_submissions")
             .update(ChurchProfileUpdate(church_name: churchName, denomination: denomination,
                                         phone: phone, website: website,
                                         service_times: serviceTimes, about: about))
             .eq("id", value: submissionId.uuidString)
             .execute()
     }

     /// Update the contact + outreach fields editable from the Edit Profile
     /// sheet (livestream URL, donation URL, social links, address, etc.).
     /// Pass an empty string to clear a field; pass nil to leave it as-is
     /// at the current row state.
     func updateChurchDetails(
         submissionId: UUID,
         contactEmail: String? = nil,
         donationUrl: String? = nil,
         livestreamUrl: String? = nil,
         addressLine: String? = nil,
         city: String? = nil,
         state: String? = nil,
         postalCode: String? = nil,
         country: String? = nil,
         pastorName: String? = nil,
         whatToExpect: String? = nil,
         ministries: String? = nil,
         facebookUrl: String? = nil,
         instagramUrl: String? = nil,
         tiktokUrl: String? = nil,
         xUrl: String? = nil,
         youtubeUrl: String? = nil
     ) async throws {
         let payload = ChurchDetailsUpdate(
             contact_email: contactEmail,
             donation_url: donationUrl,
             livestream_url: livestreamUrl,
             address_line: addressLine,
             city: city,
             state: state,
             postal_code: postalCode,
             country: country,
             pastor_name: pastorName,
             what_to_expect: whatToExpect,
             ministries: ministries,
             facebook_url: facebookUrl,
             instagram_url: instagramUrl,
             tiktok_url: tiktokUrl,
             x_url: xUrl,
             youtube_url: youtubeUrl
         )
         try await client
             .from("church_submissions")
             .update(payload)
             .eq("id", value: submissionId.uuidString)
             .execute()
     }

     /// Update the structured-schedule columns on a church submission.
     /// Pass `services` and `officeHours` for the canonical JSONB values; the
     /// legacy text columns get rewritten as auto-derived summaries.
     /// Pass `nil` for either to leave that pair untouched.
     func updateChurchSchedule(submissionId: UUID, services: [ServiceTime]?, officeHours: OfficeHours?, livestreamSchedule: LivestreamSchedule?) async throws {
         let payload = ChurchScheduleUpdate(
             service_times: services.map { ScheduleHelpers.summarizeServiceTimes($0) },
             service_times_json: services,
             office_hours: officeHours.map { ScheduleHelpers.summarizeOfficeHours($0) },
             office_hours_json: officeHours,
             livestream_schedule_json: livestreamSchedule
         )
         try await client
             .from("church_submissions")
             .update(payload)
             .eq("id", value: submissionId.uuidString)
             .execute()
     }
                                                           
     func getLiveChurches() async throws -> [ChurchSubmission] {
         // A church surfaces in the Live tab when it has a clickable stream
         // URL AND is either manually flagged live OR currently inside a
         // scheduled service window. The schedule check happens client-side
         // since Postgres can't easily evaluate JSONB schedules in a query.
         //
         // We fetch every approved church with a stream URL (cheap — most
         // churches don't set one) and let LiveChurchEvaluator decide.
         let candidates: [ChurchSubmission] = try await client
             .from("church_submissions")
             .select()
             .eq("status", value: "approved")
             .not("livestream_url", operator: .is, value: "null")
             .neq("livestream_url", value: "")
             .execute()
             .value
         return candidates.filter { LiveChurchEvaluator.isLiveNow($0) }
     }

     func getApprovedChurches() async throws -> [ChurchSubmission] {
         return try await client
             .from("church_submissions")
             .select()
             .eq("status", value: "approved")
             .execute()
             .value
     }

     func getChurchSubmissionsBySlug(_ slugs: [String]) async throws -> [ChurchSubmission] {
         guard !slugs.isEmpty else { return [] }
         let churchNames = slugs.map { $0.replacingOccurrences(of: "-", with: " ").capitalized }
         var allChurches: [ChurchSubmission] = []
         for name in churchNames {
             let churches: [ChurchSubmission] = try await client
                 .from("church_submissions")
                 .select()
                 .ilike("church_name", value: name)
                 .execute()
                 .value
             allChurches.append(contentsOf: churches)
         }
         return allChurches
     }

     // MARK: - Discover (Paginated)

     func getLiveNowChurches(limit: Int = 10) async throws -> [ChurchSubmission] {
         return try await client
             .from("church_submissions")
             .select()
             .eq("is_live", value: true)
             .eq("status", value: "approved")
             .limit(limit)
             .execute()
             .value
     }

     func getRecentlyAddedChurches(limit: Int = 8) async throws -> [ChurchSubmission] {
         return try await client
             .from("church_submissions")
             .select()
             .eq("status", value: "approved")
             .order("created_at", ascending: false)
             .limit(limit)
             .execute()
             .value
     }

     func getApprovedChurchesPaged(offset: Int, limit: Int = 20) async throws -> [ChurchSubmission] {
         return try await client
             .from("church_submissions")
             .select()
             .eq("status", value: "approved")
             .order("church_name", ascending: true)
             .range(from: offset, to: offset + limit - 1)
             .execute()
             .value
     }

     func searchChurches(
         query: String?,
         denomination: String?,
         liveOnly: Bool,
         offset: Int,
         limit: Int = 20
     ) async throws -> [ChurchSubmission] {
         var request = client
             .from("church_submissions")
             .select()
             .eq("status", value: "approved")

         if let query = query, !query.isEmpty {
             request = request.ilike("church_name", value: "%\(query)%")
         }

         if let denomination = denomination, !denomination.isEmpty {
             request = request.eq("denomination", value: denomination)
         }

         if liveOnly {
             request = request.eq("is_live", value: true)
         }

         return try await request
             .order("church_name", ascending: true)
             .range(from: offset, to: offset + limit - 1)
             .execute()
             .value
     }

     func getDiscoverableWorshippersPaged(offset: Int, limit: Int = 20) async throws -> [Profile] {
         return try await client
             .from("profiles")
             .select()
             .eq("role", value: "worshipper")
             .neq("activity_visibility", value: "private")
             .order("created_at", ascending: false)
             .range(from: offset, to: offset + limit - 1)
             .execute()
             .value
     }

     func getAllSubmissions() async throws -> [ChurchSubmission] {
         return try await client
             .from("church_submissions")
             .select()
             .execute()
             .value
     }

     // MARK: Feed / Posts
  
     func getFeedPosts() async throws -> [Post] {
         return try await client
             .from("posts")
             .select()
             .order("created_at", ascending: false)
             .limit(100)
             .execute()
             .value
     }

     func createPost(authorId: UUID, authorName: String, authorType: String,
                     content: String?, photoUrl: String?, videoUrl: String?, postType: String,
                     isImportant: Bool = false, isPinned: Bool = false,
                     sendNotification: Bool = false, highlightInFeed: Bool = false) async throws {
         try await client
             .from("posts")
             .insert(PostInsert(author_id: authorId.uuidString, author_name: authorName,
                                author_type: authorType, content: content,
                                photo_url: photoUrl?.isEmpty == true ? nil : photoUrl,
                                video_url: videoUrl?.isEmpty == true ? nil : videoUrl,
                                post_type: postType,
                                is_important: isImportant, is_pinned: isPinned,
                                send_notification: sendNotification, highlight_in_feed: highlightInFeed))
             .execute()
     }
                                                           
     func updatePost(postId: UUID, content: String?, photoUrl: String?) async throws {
         var updates: [String: AnyJSON] = [:]
         if let content = content {
             updates["content"] = .string(content)
         }
         if let photoUrl = photoUrl {
             updates["photo_url"] = .string(photoUrl)
         }

         if !updates.isEmpty {
             try await client
                 .from("posts")
                 .update(updates)
                 .eq("id", value: postId.uuidString)
                 .execute()
         }
     }

     func deletePost(postId: UUID) async throws {
         try await client
             .from("posts")
             .delete()
             .eq("id", value: postId.uuidString)
             .execute()
     }

     func deleteEvent(eventId: UUID) async throws {
         try await client
             .from("events")
             .delete()
             .eq("id", value: eventId.uuidString)
             .execute()
     }
                                                                                                                                                                                
     // MARK: Likes

     func likePost(userId: UUID, postId: UUID, currentCount: Int) async throws {
         try await client
             .from("likes")
             .insert(LikeInsert(user_id: userId.uuidString, post_id: postId.uuidString))
             .execute()
         try await client
             .from("posts")
             .update(LikeCountUpdate(like_count: currentCount + 1))
             .eq("id", value: postId.uuidString)
             .execute()
     }
                                                           
     func unlikePost(userId: UUID, postId: UUID, currentCount: Int) async throws {
         try await client
             .from("likes")
             .delete()
             .eq("user_id", value: userId.uuidString)
             .eq("post_id", value: postId.uuidString)
             .execute()
         try await client
             .from("posts")
             .update(LikeCountUpdate(like_count: max(0, currentCount - 1)))
             .eq("id", value: postId.uuidString)
             .execute()
     }

     func getLikedPostIds(userId: UUID) async throws -> Set<UUID> {
         let likes: [Like] = try await client
             .from("likes")
             .select()
             .eq("user_id", value: userId.uuidString)
             .execute()
             .value
         return Set(likes.map { $0.postId })
     }

     // MARK: Prayer responses
     //
     // Distinct from likes — prayer-typed posts let worshippers say "I prayed
     // for this." Each row in prayer_responses is unique per (user_id,
     // prayer_post_id) and the rolled-up `prayer_count` lives on `posts`.

     func prayForPost(userId: UUID, postId: UUID, currentCount: Int) async throws {
         try await client
             .from("prayer_responses")
             .insert(PrayerResponseInsert(user_id: userId.uuidString, prayer_post_id: postId.uuidString))
             .execute()
         try await client
             .from("posts")
             .update(PrayerCountUpdate(prayer_count: currentCount + 1))
             .eq("id", value: postId.uuidString)
             .execute()
     }

     func unprayForPost(userId: UUID, postId: UUID, currentCount: Int) async throws {
         try await client
             .from("prayer_responses")
             .delete()
             .eq("user_id", value: userId.uuidString)
             .eq("prayer_post_id", value: postId.uuidString)
             .execute()
         try await client
             .from("posts")
             .update(PrayerCountUpdate(prayer_count: max(0, currentCount - 1)))
             .eq("id", value: postId.uuidString)
             .execute()
     }

     func getPrayedPostIds(userId: UUID) async throws -> Set<UUID> {
         let rows: [PrayerResponseRow] = try await client
             .from("prayer_responses")
             .select("prayer_post_id")
             .eq("user_id", value: userId.uuidString)
             .execute()
             .value
         return Set(rows.compactMap { UUID(uuidString: $0.prayer_post_id) })
     }

     // MARK: Event RSVPs
     //
     // event_rsvps is keyed by (event_id, user_id). For event-typed posts
     // (post_type == "event") we use the post's `id` as the event_id since
     // the new event flow stores events as posts. The legacy `events` table
     // also routes through this — same column shape.

     func rsvpToEvent(userId: UUID, eventId: UUID) async throws {
         try await client
             .from("event_rsvps")
             .insert(EventRsvpInsert(event_id: eventId.uuidString, user_id: userId.uuidString))
             .execute()
     }

     func cancelRsvp(userId: UUID, eventId: UUID) async throws {
         try await client
             .from("event_rsvps")
             .delete()
             .eq("event_id", value: eventId.uuidString)
             .eq("user_id", value: userId.uuidString)
             .execute()
     }

     func getRsvpedEventIds(userId: UUID) async throws -> Set<UUID> {
         let rows: [EventRsvpRow] = try await client
             .from("event_rsvps")
             .select("event_id")
             .eq("user_id", value: userId.uuidString)
             .execute()
             .value
         return Set(rows.compactMap { UUID(uuidString: $0.event_id) })
     }

     func getRsvpCount(eventId: UUID) async throws -> Int {
         let rows: [EventRsvpRow] = try await client
             .from("event_rsvps")
             .select("event_id")
             .eq("event_id", value: eventId.uuidString)
             .execute()
             .value
         return rows.count
     }

     // MARK: Device tokens (APNs push)
     //
     // Single-table design — see supabase/migrations/20260508_device_tokens.sql.
     // Upsert on (token, user_id); RLS guarantees a user can only see/write
     // their own rows. The Edge Function `send-push` reads them via service
     // role and signs APNs JWTs to fan out.

     func upsertDeviceToken(
         userId: UUID,
         token: String,
         platform: String,
         appVersion: String?,
         deviceModel: String?,
         osVersion: String?
     ) async throws {
         try await client
             .from("device_tokens")
             .upsert(
                 DeviceTokenUpsert(
                     user_id: userId.uuidString,
                     token: token,
                     platform: platform,
                     app_version: appVersion,
                     device_model: deviceModel,
                     os_version: osVersion
                 ),
                 onConflict: "token,user_id"
             )
             .execute()
     }

     func deleteDeviceToken(userId: UUID, token: String) async throws {
         try await client
             .from("device_tokens")
             .delete()
             .eq("user_id", value: userId.uuidString)
             .eq("token", value: token)
             .execute()
     }

     // MARK: Follows
                                                           
     func follow(followerId: UUID, followingId: String, followingType: String) async throws {
         try await client
             .from("follows")
             .insert(FollowInsert(follower_id: followerId.uuidString,
                                  following_id: followingId,
                                  following_type: followingType))
             .execute()
     }

     func unfollow(followerId: UUID, followingId: String) async throws {
         try await client
             .from("follows")
             .delete()
             .eq("follower_id", value: followerId.uuidString)
             .eq("following_id", value: followingId)
             .execute()
     }
  
     func getFollowing(followerId: UUID) async throws -> [Follow] {
         return try await client
             .from("follows")
             .select()
             .eq("follower_id", value: followerId.uuidString)
             .execute()
             .value
     }
                                                                                                                                                                                
     func getFollowerCount(followingId: String) async throws -> Int {
         let rows: [Follow] = try await client
             .from("follows")
             .select()
             .eq("following_id", value: followingId)
             .execute()
             .value
         return rows.count
     }

     // MARK: Events

     func getUpcomingEvents() async throws -> [Event] {
         let now = ISO8601DateFormatter().string(from: Date())
         return try await client
             .from("events")
             .select()
             .gte("event_date", value: now)
             .order("event_date", ascending: true)
             .limit(20)
             .execute()
             .value
     }

     func createEvent(authorId: UUID, authorName: String, title: String,
                      description: String?, eventDate: Date, location: String?) async throws {
         let formatter = ISO8601DateFormatter()
         try await client
             .from("events")
             .insert(EventInsert(author_id: authorId.uuidString, author_name: authorName,
                                 title: title, description: description,
                                 event_date: formatter.string(from: eventDate),
                                 location: location))
             .execute()
     }
                                                                                                                                                                                
     func getPostsByAuthor(authorName: String) async throws -> [Post] {
         return try await client
             .from("posts")
             .select()
             .eq("author_name", value: authorName)
             .order("created_at", ascending: false)
             .limit(50)
             .execute()
             .value
     }

     func getUserPosts(userId: UUID) async throws -> [Post] {
         return try await client
             .from("posts")
             .select()
             .eq("author_id", value: userId.uuidString)
             .order("created_at", ascending: false)
             .limit(50)
             .execute()
             .value
     }

     func getEventsByAuthor(authorName: String) async throws -> [Event] {
         let now = ISO8601DateFormatter().string(from: Date())
         return try await client
             .from("events")
             .select()
             .eq("author_name", value: authorName)
             .gte("event_date", value: now)
             .order("event_date", ascending: true)
             .execute()
             .value
     }
  
     func isFollowingUser(followerId: UUID, subjectId: UUID) async throws -> Bool {
         let rows: [Follow] = try await client
             .from("follows")
             .select()
             .eq("follower_id", value: followerId.uuidString)
             .eq("following_id", value: subjectId.uuidString)
             .eq("following_type", value: "worshipper")
             .execute()
             .value
         return !rows.isEmpty
     }

     func isFollowingChurch(followerId: UUID, churchSlug: String) async throws -> Bool {
         let rows: [Follow] = try await client
             .from("follows")
             .select()
             .eq("follower_id", value: followerId.uuidString)
             .eq("following_id", value: churchSlug)
             .execute()
             .value
         return !rows.isEmpty
     }

     // MARK: Notifications

     func getNotifications(userId: UUID) async throws -> [AppNotification] {
         return try await client
             .from("notifications")
             .select()
             .eq("user_id", value: userId.uuidString)
             .order("created_at", ascending: false)
             .execute()
             .value
     }
                                                                                                                                                                                
     func markNotificationRead(notificationId: UUID) async throws {
         try await client
             .from("notifications")
             .update(NotificationReadUpdate(is_read: true))
             .eq("id", value: notificationId.uuidString)
             .execute()
     }
                                                                                                                                                                                
     func markAllNotificationsRead(userId: UUID) async throws {
         try await client
             .from("notifications")
             .update(NotificationReadUpdate(is_read: true))
             .eq("user_id", value: userId.uuidString)
             .execute()
     }

     // MARK: Church Inquiries

     func submitInquiry(memberId: UUID, memberName: String,
                        churchSlug: String, churchName: String,
                        type: String, subject: String, body: String) async throws {
         try await client
             .from("church_inquiries")
             .insert(ChurchInquiryInsert(
                 member_id:   memberId.uuidString,
                 member_name: memberName,
                 church_slug: churchSlug,
                 church_name: churchName,
                 type:        type,
                 subject:     subject,
                 body:        body
             ))
             .execute()
     }

     func getInquiries(churchName: String) async throws -> [ChurchInquiry] {
         return try await client
             .from("church_inquiries")
             .select()
             .eq("church_name", value: churchName)
             .order("created_at", ascending: false)
             .execute()
             .value
     }

     func updateInquiryStatus(id: UUID, status: InquiryStatus) async throws {
         try await client
             .from("church_inquiries")
             .update(InquiryStatusUpdate(status: status.rawValue))
             .eq("id", value: id.uuidString)
             .execute()
     }

     /// Permanently remove an inquiry. Used by the church admin's Inbox so
     /// they can clear out spam / handled messages they don't want to keep.
     func deleteInquiry(id: UUID) async throws {
         try await client
             .from("church_inquiries")
             .delete()
             .eq("id", value: id.uuidString)
             .execute()
     }

     /// Save an in-app reply to an inquiry. Stores the text in
     /// `reply_text`, stamps `replied_at`, flips `status = "replied"`,
     /// and inserts a `church_inquiry_reply` notification for the member
     /// so they're alerted on the worshipper side.
     ///
     /// Notification insert is best-effort — if it fails we still keep the
     /// reply (the church wrote it; losing the alert is recoverable, losing
     /// the message body is not).
     func replyToInquiry(inquiry: ChurchInquiry, text: String) async throws {
         struct InquiryReplyUpdate: Encodable {
             let reply_text: String
             let replied_at: String
             let status: String
         }
         let payload = InquiryReplyUpdate(
             reply_text: text,
             replied_at: ISO8601DateFormatter().string(from: Date()),
             status: InquiryStatus.replied.rawValue
         )
         try await client
             .from("church_inquiries")
             .update(payload)
             .eq("id", value: inquiry.id.uuidString)
             .execute()

         // Notify the member.
         struct InquiryReplyNotification: Encodable {
             let user_id: String
             let type: String
             let title: String
             let body: String
             let related_id: String
             let church_slug: String
         }
         let preview: String = {
             let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
             return trimmed.count > 120 ? String(trimmed.prefix(120)) + "…" : trimmed
         }()
         let notif = InquiryReplyNotification(
             user_id:     inquiry.memberId.uuidString,
             type:        "church_inquiry_reply",
             title:       "\(inquiry.churchName) replied to your message",
             body:        preview,
             related_id:  inquiry.id.uuidString,
             church_slug: inquiry.churchSlug
         )
         _ = try? await client
             .from("notifications")
             .insert(notif)
             .execute()
     }

     /// Worshipper-side: every inquiry this member has submitted, newest first.
     /// Powers the Messages screen on the WorshipperDashboard.
     func getInquiriesForMember(memberId: UUID) async throws -> [ChurchInquiry] {
         return try await client
             .from("church_inquiries")
             .select()
             .eq("member_id", value: memberId.uuidString)
             .order("created_at", ascending: false)
             .execute()
             .value
     }

     /// Single-column lookup for the inquiry detail's "Reply via Email" path.
     /// Returns nil when the profile row has no email (Supabase auth users
     /// can have email in `auth.users` but not mirrored to `profiles.email`).
     func getProfileEmail(userId: UUID) async throws -> String? {
         struct EmailRow: Decodable { let email: String? }
         let rows: [EmailRow] = try await client
             .from("profiles")
             .select("email")
             .eq("id", value: userId.uuidString)
             .limit(1)
             .execute()
             .value
         return rows.first?.email
     }

     // MARK: Comments

     func getComments(postId: UUID) async throws -> [Comment] {
         let comments: [Comment] = try await client
             .from("comments")
             .select()
             .eq("post_id", value: postId.uuidString)
             .order("created_at", ascending: false)
             .execute()
             .value
         return comments
     }

     func postComment(postId: UUID, userId: UUID, authorName: String, authorPhotoUrl: String?, content: String) async throws {
         try await client
             .from("comments")
             .insert([
                 "post_id": postId.uuidString,
                 "user_id": userId.uuidString,
                 "author_name": authorName,
                 "author_type": "worshipper",
                 "author_photo_url": authorPhotoUrl,
                 "content": content
             ])
             .execute()
     }

     // MARK: Trust & safety

     /// Submit a content report. RLS allows any signed-in user to insert,
     /// and the admin moderation queue (web /admin/reports) reviews them.
     func reportContent(reporterId: UUID?, contentType: FlagContentType,
                        contentId: UUID, reason: FlagReason, notes: String?) async throws {
         struct FlagInsert: Encodable {
             let reporter_id: String?
             let content_type: String
             let content_id: String
             let reason: String
             let notes: String?
             let status: String
         }
         try await client
             .from("flagged_content")
             .insert(FlagInsert(
                 reporter_id: reporterId?.uuidString,
                 content_type: contentType.rawValue,
                 content_id: contentId.uuidString,
                 reason: reason.rawValue,
                 notes: notes,
                 status: "pending"
             ))
             .execute()
     }

     /// Block a user. Idempotent — re-blocking just upserts.
     func blockUser(blockerId: UUID, blockedId: UUID, reason: String? = nil) async throws {
         struct BlockUpsert: Encodable {
             let blocker_id: String
             let blocked_id: String
             let reason: String?
         }
         try await client
             .from("user_blocks")
             .upsert(
                 BlockUpsert(
                     blocker_id: blockerId.uuidString,
                     blocked_id: blockedId.uuidString,
                     reason: reason
                 ),
                 onConflict: "blocker_id,blocked_id"
             )
             .execute()
     }

     func unblockUser(blockerId: UUID, blockedId: UUID) async throws {
         try await client
             .from("user_blocks")
             .delete()
             .eq("blocker_id", value: blockerId.uuidString)
             .eq("blocked_id", value: blockedId.uuidString)
             .execute()
     }

     /// Soft-dismiss a single post from the viewer's feed only.
     func hidePost(userId: UUID, postId: UUID) async throws {
         struct HideUpsert: Encodable {
             let user_id: String
             let post_id: String
         }
         try await client
             .from("hidden_posts")
             .upsert(
                 HideUpsert(user_id: userId.uuidString, post_id: postId.uuidString),
                 onConflict: "user_id,post_id"
             )
             .execute()
     }

     // MARK: Notification preferences

     /// Load the signed-in user's notification preferences. Returns the
     /// hardcoded defaults when no row exists yet, so first-load doesn't
     /// need a separate code path.
     func getNotificationPreferences(userId: UUID) async throws -> NotificationPreferences {
         struct Row: Decodable {
             let new_followers: Bool
             let new_likes: Bool
             let new_comments: Bool
             let prayer_responses: Bool
             let church_updates: Bool
             let church_live: Bool
             let inquiry_replies: Bool
             let new_inquiries: Bool
             let push_enabled: Bool
         }
         do {
             let rows: [Row] = try await client
                 .from("notification_preferences")
                 .select()
                 .eq("user_id", value: userId.uuidString)
                 .limit(1)
                 .execute()
                 .value
             guard let r = rows.first else { return .defaults }
             return NotificationPreferences(
                 newFollowers:    r.new_followers,
                 newLikes:        r.new_likes,
                 newComments:     r.new_comments,
                 prayerResponses: r.prayer_responses,
                 churchUpdates:   r.church_updates,
                 churchLive:      r.church_live,
                 inquiryReplies:  r.inquiry_replies,
                 newInquiries:    r.new_inquiries,
                 pushEnabled:     r.push_enabled
             )
         } catch {
             // Treat fetch failures as "use defaults" so the screen stays
             // usable. The save path below will create a row on first edit.
             print("[notif-prefs] load failed: \(error.localizedDescription)")
             return .defaults
         }
     }

     /// Upsert the user's preferences. Service-side trigger is what
     /// actually filters notifications; this just persists the choices.
     func saveNotificationPreferences(userId: UUID, prefs: NotificationPreferences) async throws {
         struct PrefUpsert: Encodable {
             let user_id: String
             let new_followers: Bool
             let new_likes: Bool
             let new_comments: Bool
             let prayer_responses: Bool
             let church_updates: Bool
             let church_live: Bool
             let inquiry_replies: Bool
             let new_inquiries: Bool
             let push_enabled: Bool
             let updated_at: String
         }
         let payload = PrefUpsert(
             user_id:          userId.uuidString,
             new_followers:    prefs.newFollowers,
             new_likes:        prefs.newLikes,
             new_comments:     prefs.newComments,
             prayer_responses: prefs.prayerResponses,
             church_updates:   prefs.churchUpdates,
             church_live:      prefs.churchLive,
             inquiry_replies:  prefs.inquiryReplies,
             new_inquiries:    prefs.newInquiries,
             push_enabled:     prefs.pushEnabled,
             updated_at:       ISO8601DateFormatter().string(from: Date())
         )
         try await client
             .from("notification_preferences")
             .upsert(payload, onConflict: "user_id")
             .execute()
     }

     /// Pulls the viewer's block list with display data resolved — used by
     /// the Blocked Accounts management screen. For each blocked_id we look
     /// up both `profiles` and `church_submissions`; if the blocked account
     /// is a church we prefer the church identity (name + avatar).
     func getBlockedAccounts(userId: UUID) async throws -> [BlockedEntry] {
         struct BlockRow: Decodable {
             let blocked_id: UUID
             let reason: String?
             let created_at: Date
         }
         struct ProfileRow: Decodable {
             let id: UUID
             let full_name: String?
             let photo_url: String?
             let role: String?
         }
         struct ChurchRow: Decodable {
             let user_id: UUID
             let church_name: String?
             let avatar_url: String?
         }

         let rows: [BlockRow] = try await client
             .from("user_blocks")
             .select("blocked_id, reason, created_at")
             .eq("blocker_id", value: userId.uuidString)
             .order("created_at", ascending: false)
             .execute()
             .value
         if rows.isEmpty { return [] }

         let ids = rows.map(\.blocked_id.uuidString)

         async let profilesTask: [ProfileRow] = client
             .from("profiles")
             .select("id, full_name, photo_url, role")
             .in("id", values: ids)
             .execute()
             .value
         async let churchesTask: [ChurchRow] = client
             .from("church_submissions")
             .select("user_id, church_name, avatar_url")
             .in("user_id", values: ids)
             .eq("status", value: "approved")
             .execute()
             .value

         let (profiles, churches) = try await (profilesTask, churchesTask)
         let profileById = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })
         let churchByUserId = Dictionary(uniqueKeysWithValues: churches.map { ($0.user_id, $0) })

         return rows.map { row in
             if let church = churchByUserId[row.blocked_id] {
                 let slug = (church.church_name ?? "")
                     .lowercased()
                     .replacingOccurrences(of: " ", with: "-")
                 return BlockedEntry(
                     blockedId: row.blocked_id,
                     name: church.church_name ?? "Unknown church",
                     photoUrl: church.avatar_url,
                     kind: .church,
                     slug: slug,
                     reason: row.reason,
                     blockedAt: row.created_at
                 )
             } else {
                 let p = profileById[row.blocked_id]
                 return BlockedEntry(
                     blockedId: row.blocked_id,
                     name: p?.full_name ?? "Unknown account",
                     photoUrl: p?.photo_url,
                     kind: .person,
                     slug: nil,
                     reason: row.reason,
                     blockedAt: row.created_at
                 )
             }
         }
     }

     /// Pulls the current viewer's block + hide lists. Used to filter the
     /// feed and any other surface that shouldn't render dismissed content.
     func getSafetyFilters(userId: UUID) async throws
         -> (blockedUserIds: Set<UUID>, hiddenPostIds: Set<UUID>) {
         struct BlockedRow: Decodable { let blocked_id: UUID }
         struct HiddenRow: Decodable  { let post_id:    UUID }

         async let blocks: [BlockedRow] = client
             .from("user_blocks")
             .select("blocked_id")
             .eq("blocker_id", value: userId.uuidString)
             .execute()
             .value
         async let hides: [HiddenRow] = client
             .from("hidden_posts")
             .select("post_id")
             .eq("user_id", value: userId.uuidString)
             .execute()
             .value

         let (b, h) = try await (blocks, hides)
         return (
             Set(b.map(\.blocked_id)),
             Set(h.map(\.post_id))
         )
     }

     // MARK: Database seeding (testing only)

     func cleanAndSeedDatabase(adminUserId: UUID? = nil) async throws {
         let seeder = DatabaseSeeder(client: client, adminUserId: adminUserId)
         try await seeder.cleanAndSeed()
     }
 }
       
