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
                                                                                                                                                                                
     let client = SupabaseClient(
         supabaseURL: URL(string: "https://hjckwtjzvuacpckqsasa.supabase.co")!,
         supabaseKey: "sb_publishable_pqw_JTJYaDbmWAN7UhkvfQ_DRsijAuH"
     )
                                                                                                                                                                                
     // MARK: Auth
                                                           
     func signIn(email: String, password: String) async throws {
         try await client.auth.signIn(email: email, password: password)
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

    func getProfiles(ids: [UUID]) async throws -> [Profile] {
        guard !ids.isEmpty else { return [] }
        let all: [Profile] = try await client
            .from("profiles")
            .select()
            .execute()
            .value
        return all.filter { ids.contains($0.id) }
    }

    func getFollowers(userId: UUID) async throws -> [Follow] {
        return try await client
            .from("follows")
            .select()
            .eq("following_id", value: userId.uuidString)
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
                                                           
     func getLiveChurches() async throws -> [ChurchSubmission] {
         return try await client
             .from("church_submissions")
             .select()
             .eq("is_live", value: true)
             .eq("status", value: "approved")
             .execute()
             .value
     }

     func getApprovedChurches() async throws -> [ChurchSubmission] {
         return try await client
             .from("church_submissions")
             .select()
             .eq("status", value: "approved")
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

     // MARK: Comments

     func getComments(postId: UUID) async throws -> [Comment] {
         let response = try await client
             .from("comments")
             .select()
             .eq("post_id", value: postId.uuidString)
             .order("created_at", ascending: false)
             .execute()

         return try JSONDecoder().decode([Comment].self, from: JSONSerialization.data(withJSONObject: response.value as Any))
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
 }
       
