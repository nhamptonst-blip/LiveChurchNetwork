import Foundation

// MARK: - Privacy

enum PrivacySetting: String, Codable, CaseIterable {
    case `public`      = "public"
    case followersOnly = "followers_only"
    case `private`     = "private"

    var label: String {
        switch self {
        case .public:        return "Public"
        case .followersOnly: return "Followers Only"
        case .private:       return "Private"
        }
    }

    /// Shortened label for use in segmented controls.
    var shortLabel: String {
        switch self {
        case .public:        return "Public"
        case .followersOnly: return "Followers"
        case .private:       return "Private"
        }
    }

    var icon: String {
        switch self {
        case .public:        return "globe"
        case .followersOnly: return "person.2.fill"
        case .private:       return "lock.fill"
        }
    }
}

// MARK: - Shared Constants

let denominationOptions: [String] = [
    "Non-Denominational", "Baptist", "Catholic", "Methodist",
    "Pentecostal", "Orthodox", "Presbyterian", "Lutheran", "Evangelical",
    "Episcopal", "Anglican", "Reformed", "Church of Christ",
    "Assemblies of God", "Seventh-day Adventist",
    "African Methodist Episcopal (AME)", "Other"
]

  // MARK: - Church (static directory)

  struct Church: Identifiable, Equatable, Hashable {
      let id = UUID()
      let name: String
      let slug: String
      let image: String
      let denomination: String
      let permalink: String
      let phone: String
      var email: String = ""
      var address: String = ""
      let website: String
      var donationUrl: String = ""
      let serviceTimes: String
      let about: String
      var isLive: Bool = false
      var isVerified: Bool = false
      var isTrending: Bool = false
      var isNew: Bool = false
      var city: String = ""
      var coverImage: String = ""
      var pastorName: String = ""
      var followerCount: Int = 0
      var livestreamUrl: String = ""
      var liveViewerCount: Int = 0
      var languages: String = ""
      var ministries: String = ""
      var worshipStyle: String = ""
      var latitude: Double? = nil
      var longitude: Double? = nil

      var followerCountDisplay: String {
          if followerCount >= 1000 {
              return String(format: "%.1fk", Double(followerCount) / 1000).replacingOccurrences(of: ".0k", with: "k")
          }
          return String(followerCount)
      }

      var hasWebsite: Bool { !website.isEmpty }
      var hasPhone: Bool { !phone.isEmpty }
      var hasEmail: Bool { !email.isEmpty }
      var hasDonationUrl: Bool { !donationUrl.isEmpty }
      var hasLivestream: Bool { !livestreamUrl.isEmpty }
      var hasLocation: Bool { !city.isEmpty }
      var hasAddress: Bool { !address.isEmpty && address != "No address on file" }
  }

  // MARK: - Supabase models

  struct Profile: Codable, Identifiable {
      let id: UUID
      let role: String?
      let fullName: String?
      let city: String?
      let denomination: String?
      let bio: String?
      let languages: String?
      let photoUrl: String?   // Requires: photo_url text column in profiles table
      let coverUrl: String?   // Requires: cover_url text column in profiles table

      // Worshipper's declared home church. Two mutually-exclusive fields:
      //   homeChurchSlug — references a static directory church (tappable)
      //   homeChurchName — free-text name for churches not in the directory
      // Requires: home_church_slug text, home_church_name text columns in profiles.
      let homeChurchSlug: String?
      let homeChurchName: String?

      // Privacy settings — stored as raw strings; default to "public" when nil.
      // Requires columns in profiles table:
      //   activity_visibility text default 'public'
      //   followers_visibility text default 'public'
      //   following_visibility text default 'public'
      //   churches_visibility  text default 'public'
      let activityVisibility:  String?
      let followersVisibility: String?
      let followingVisibility: String?
      let churchesVisibility:  String?
      let createdAt: Date?
      let isLeader: Bool?
      let isDiscoverable: Bool?
      let isSearchable: Bool?
      let showHomeChurch: Bool?
      let showFollowers: Bool?
      let showFollowing: Bool?
      let favoriteScripture: String?
      let isBanned: Bool?

      var activityPrivacy:  PrivacySetting { PrivacySetting(rawValue: activityVisibility  ?? "") ?? .public }
      var followersPrivacy: PrivacySetting { PrivacySetting(rawValue: followersVisibility ?? "") ?? .public }
      var followingPrivacy: PrivacySetting { PrivacySetting(rawValue: followingVisibility ?? "") ?? .public }
      var churchesPrivacy:  PrivacySetting { PrivacySetting(rawValue: churchesVisibility  ?? "") ?? .public }

      var displayName: String {
          fullName?.isEmpty == false ? fullName! : "Worshipper"
      }

      var hasProfilePhoto: Bool { photoUrl != nil && !photoUrl!.isEmpty }
      var hasCoverPhoto: Bool { coverUrl != nil && !coverUrl!.isEmpty }
      var hasHomeChurch: Bool { homeChurchSlug != nil || homeChurchName != nil }

      enum CodingKeys: String, CodingKey {
          case id, role, city, denomination, bio, languages
          case fullName            = "full_name"
          case photoUrl            = "photo_url"
          case coverUrl            = "cover_url"
          case homeChurchSlug      = "home_church_slug"
          case homeChurchName      = "home_church_name"
          case activityVisibility  = "activity_visibility"
          case followersVisibility = "followers_visibility"
          case followingVisibility = "following_visibility"
          case churchesVisibility  = "churches_visibility"
          case createdAt           = "created_at"
          case isLeader            = "is_leader"
          case isDiscoverable      = "is_discoverable"
          case isSearchable        = "is_searchable"
          case showHomeChurch      = "show_home_church"
          case showFollowers       = "show_followers"
          case showFollowing       = "show_following"
          case favoriteScripture   = "favorite_scripture"
          case isBanned            = "is_banned"
      }
  }

  // MARK: - User discovery

  struct DiscoverableUser: Identifiable {
      let id: UUID
      let name: String
      let bio: String?
      let denomination: String?
      let city: String?
      let photoUrl: String?
      var coverImageUrl: String? = nil
      var homeChurchName: String? = nil
      var followerCount: Int = 0
      var followingCount: Int = 0
      var churchSlugs: [String] = []
      var isLeader: Bool = false
      // Privacy settings — what this user has chosen to share with others.
      var activityPrivacy:  PrivacySetting = .public
      var followersPrivacy: PrivacySetting = .public
      var followingPrivacy: PrivacySetting = .public
      var churchesPrivacy:  PrivacySetting = .public
      // Discovery privacy — defaults allow discovery
      var isDiscoverable: Bool = true
      var isSearchable: Bool = true
      var showHomeChurch: Bool = true
      var showFollowers: Bool = true
      var showFollowing: Bool = true

      var hasProfilePhoto: Bool { photoUrl != nil && !photoUrl!.isEmpty }
      var hasCoverImage: Bool { coverImageUrl != nil && !coverImageUrl!.isEmpty }
      var hasBio: Bool { bio != nil && !bio!.isEmpty }

      var followerCountDisplay: String {
          if followerCount >= 1000 {
              return String(format: "%.1fk", Double(followerCount) / 1000).replacingOccurrences(of: ".0k", with: "k")
          }
          return String(followerCount)
      }

      var followingCountDisplay: String {
          if followingCount >= 1000 {
              return String(format: "%.1fk", Double(followingCount) / 1000).replacingOccurrences(of: ".0k", with: "k")
          }
          return String(followingCount)
      }
  }

  // MARK: - Church Inquiries (structured church-member communication)

  /// Category of a member's inquiry to a church.
  enum InquiryType: String, Codable, CaseIterable {
      case general   = "general"
      case prayer    = "prayer"
      case visit     = "visit"
      case volunteer = "volunteer"
      case event     = "event"

      var label: String {
          switch self {
          case .general:   return "Question"
          case .prayer:    return "Prayer"
          case .visit:     return "Visit"
          case .volunteer: return "Volunteer"
          case .event:     return "Event"
          }
      }

      var fullLabel: String {
          switch self {
          case .general:   return "General Question"
          case .prayer:    return "Prayer Request"
          case .visit:     return "Plan a Visit"
          case .volunteer: return "Volunteer Interest"
          case .event:     return "Event Question"
          }
      }

      var icon: String {
          switch self {
          case .general:   return "questionmark.circle.fill"
          case .prayer:    return "hands.sparkles.fill"
          case .visit:     return "calendar.badge.plus"
          case .volunteer: return "heart.circle.fill"
          case .event:     return "ticket.fill"
          }
      }

      var placeholder: String {
          switch self {
          case .general:
              return "What would you like to know?"
          case .prayer:
              return "Share your prayer request. This is only seen by church staff."
          case .visit:
              return "Let them know when you're planning to visit and any questions you have."
          case .volunteer:
              return "What areas interest you? (e.g., music, hospitality, youth ministry)"
          case .event:
              return "Which event are you asking about, and what would you like to know?"
          }
      }
  }

  /// Lifecycle state of a church inquiry.
  enum InquiryStatus: String, Codable {
      case new      = "new"
      case replied  = "replied"
      case archived = "archived"

      var label: String {
          switch self {
          case .new:      return "New"
          case .replied:  return "Replied"
          case .archived: return "Archived"
          }
      }
  }

  struct ChurchInquiry: Codable, Identifiable {
      let id: UUID
      let memberId: UUID
      let memberName: String
      let churchSlug: String
      let churchName: String
      let type: String           // InquiryType.rawValue
      let subject: String
      let body: String
      var status: String         // InquiryStatus.rawValue
      let createdAt: Date
      // In-app reply written by the church admin. Single reply for now;
      // threading would require a separate inquiry_messages table.
      var replyText: String?
      var repliedAt: Date?

      var inquiryType: InquiryType  { InquiryType(rawValue: type)     ?? .general }
      var inquiryStatus: InquiryStatus { InquiryStatus(rawValue: status) ?? .new }

      var isNew: Bool { inquiryStatus == .new }
      var isReplied: Bool { inquiryStatus == .replied }
      var isArchived: Bool { inquiryStatus == .archived }

      var createdAtFormatted: String {
          let formatter = DateFormatter()
          formatter.dateStyle = .medium
          return formatter.string(from: createdAt)
      }

      enum CodingKeys: String, CodingKey {
          case id, type, subject, body, status
          case memberId   = "member_id"
          case memberName = "member_name"
          case churchSlug = "church_slug"
          case churchName = "church_name"
          case createdAt  = "created_at"
          case replyText  = "reply_text"
          case repliedAt  = "replied_at"
      }
  }

  // MARK: - Church Leadership

  struct Leader: Identifiable {
      let id: UUID
      let name: String
      let title: String
      let bio: String?
      let photoUrl: String?
  }

  struct ChurchSubmission: Codable, Identifiable {
      let id: UUID
      let userId: UUID
      var churchName: String?
      var isLive: Bool
      var status: String?
      var denomination: String?
      var phone: String?
      var website: String?
      var serviceTimes: String?
      var about: String?
      var whatToExpect: String?
      var city: String?
      var state: String?
      var country: String?
      var postalCode: String?
      var addressLine: String?
      var donationUrl: String?
      var contactEmail: String?
      var pastorName: String?
      var yearFounded: Int?
      var facebookUrl: String?
      var instagramUrl: String?
      var tiktokUrl: String?
      var xUrl: String?
      var youtubeUrl: String?
      var languages: String?
      var avatarUrl: String?
      var officeHours: String?
      var leadershipTeam: [String: String]?
      var ministries: String?
      var podcastUrl: String?
      var livestreamUrl: String?
      var latitude: Double?
      var longitude: Double?
      var worshipStyle: String?
      // Cover photo (matches web's church_submissions.cover_url)
      var coverUrl: String?
      // Structured schedule (web stack adds these alongside the legacy text columns).
      // Legacy serviceTimes/officeHours strings remain in sync as auto-derived summaries.
      var serviceTimesJson: [ServiceTime]?
      var officeHoursJson: OfficeHours?
      var livestreamScheduleJson: LivestreamSchedule?
      var scheduleTimezone: String?
      // Notify followers when this church goes live (column added by the
      // web settings migration). iOS persists the admin's preference;
      // enforcement still lives in the notification trigger.
      var notifyFollowers: Bool?

      enum CodingKeys: String, CodingKey {
          case id, status, denomination, phone, website, about
          case userId          = "user_id"
          case churchName      = "church_name"
          case isLive          = "is_live"
          case serviceTimes    = "service_times"
          case whatToExpect    = "what_to_expect"
          case city, state, country
          case postalCode      = "postal_code"
          case addressLine     = "address_line"
          case donationUrl     = "donation_url"
          case contactEmail    = "contact_email"
          case pastorName      = "pastor_name"
          case yearFounded     = "year_founded"
          case facebookUrl     = "facebook_url"
          case instagramUrl    = "instagram_url"
          case tiktokUrl       = "tiktok_url"
          case xUrl            = "x_url"
          case youtubeUrl      = "youtube_url"
          case languages
          case avatarUrl       = "avatar_url"
          case coverUrl        = "cover_url"
          case officeHours     = "office_hours"
          case leadershipTeam  = "leadership_team"
          case ministries
          case podcastUrl      = "podcast_url"
          case livestreamUrl   = "livestream_url"
          case latitude
          case longitude
          case worshipStyle    = "worship_style"
          case serviceTimesJson = "service_times_json"
          case officeHoursJson  = "office_hours_json"
          case livestreamScheduleJson = "livestream_schedule_json"
          case scheduleTimezone = "schedule_timezone"
          case notifyFollowers  = "notify_followers"
      }
  }

  struct SavedChurch: Codable, Identifiable {
      let id: UUID
      let userId: UUID
      let churchSlug: String

      enum CodingKeys: String, CodingKey {
          case id
          case userId     = "user_id"
          case churchSlug = "church_slug"
      }
  }

  // MARK: - Feed / Social

  struct Post: Codable, Identifiable, Hashable {
      let id: UUID
      let authorId: UUID
      let authorName: String
      let authorType: String
      let title: String?
      let content: String?
      let photoUrl: String?
      let videoUrl: String?
      let postType: String
      var likeCount: Int
      var prayerCount: Int?            // separate from likes (prayer_responses)
      var isImportant: Bool = false
      var isPinned: Bool = false
      var sendNotification: Bool = false
      var highlightInFeed: Bool = false
      let createdAt: Date
      // Wall posts — when a worshipper posts on a church's profile
      var postedOnId: String?
      var postedOnType: String?
      // Event-typed posts carry date + location inline
      var eventDate: Date?
      var eventLocation: String?
      var isLiked: Bool = false

      var isChurchPost: Bool { authorType == "church" }
      var hasMedia: Bool { photoUrl != nil || videoUrl != nil }
      var likeCountDisplay: String {
          if likeCount >= 1000 {
              return String(format: "%.1fk", Double(likeCount) / 1000).replacingOccurrences(of: ".0k", with: "k")
          }
          return String(likeCount)
      }

      enum CodingKeys: String, CodingKey {
          case id, title, content
          case authorId   = "author_id"
          case authorName = "author_name"
          case authorType = "author_type"
          case photoUrl   = "photo_url"
          case videoUrl   = "video_url"
          case postType   = "post_type"
          case likeCount  = "like_count"
          case prayerCount = "prayer_count"
          case isImportant = "is_important"
          case isPinned = "is_pinned"
          case sendNotification = "send_notification"
          case highlightInFeed = "highlight_in_feed"
          case createdAt  = "created_at"
          case postedOnId = "posted_on_id"
          case postedOnType = "posted_on_type"
          case eventDate = "event_date"
          case eventLocation = "event_location"
      }
  }

  struct Event: Codable, Identifiable {
      let id: UUID
      let authorId: UUID
      let authorName: String
      let title: String
      let description: String?
      let eventDate: Date
      let location: String?
      let createdAt: Date

      var isPastEvent: Bool {
          eventDate < Date()
      }

      var eventDateFormatted: String {
          let formatter = DateFormatter()
          formatter.dateStyle = .medium
          formatter.timeStyle = .short
          return formatter.string(from: eventDate)
      }

      enum CodingKeys: String, CodingKey {
          case id, title, description, location
          case authorId   = "author_id"
          case authorName = "author_name"
          case eventDate  = "event_date"
          case createdAt  = "created_at"
      }
  }

  struct Follow: Codable, Identifiable {
      let id: UUID
      let followerId: UUID
      let followingId: String
      let followingType: String
      let createdAt: Date

      enum CodingKeys: String, CodingKey {
          case id
          case followerId    = "follower_id"
          case followingId   = "following_id"
          case followingType = "following_type"
          case createdAt     = "created_at"
      }
  }

  struct Like: Codable, Identifiable {
      let id: UUID
      let userId: UUID
      let postId: UUID
      let createdAt: Date

      enum CodingKeys: String, CodingKey {
          case id
          case userId    = "user_id"
          case postId    = "post_id"
          case createdAt = "created_at"
      }
  }

  struct AppNotification: Codable, Identifiable {
      let id: UUID
      let userId: UUID
      let type: String
      let title: String
      let body: String?
      let relatedId: UUID?
      /// UUID of the user who performed the action (e.g. the follower in new_follower).
      let actorUserId: UUID?
      /// Church slug for church-related notifications.
      let churchSlug: String?
      /// Post UUID when the notification is about a specific post.
      let postId: UUID?
      /// Event UUID when the notification is about a specific event.
      let eventId: UUID?
      var isRead: Bool
      let createdAt: Date

      var isChurchRelated: Bool { churchSlug != nil }
      var isPostRelated: Bool { postId != nil }
      var isEventRelated: Bool { eventId != nil }

      var notificationIcon: String {
          switch type {
          case "new_follower":           return "person.badge.plus"
          case "new_like":               return "heart.fill"
          case "church_live":            return "play.circle.fill"
          case "new_post":               return "doc.text"
          case "new_event":              return "calendar"
          case "church_inquiry_reply":   return "envelope.open"
          default:                       return "bell"
          }
      }

      var createdAtFormatted: String {
          let formatter = DateFormatter()
          formatter.dateStyle = .short
          formatter.timeStyle = .short
          return formatter.string(from: createdAt)
      }

      enum CodingKeys: String, CodingKey {
          case id, type, title, body
          case userId      = "user_id"
          case relatedId   = "related_id"
          case actorUserId = "actor_user_id"
          case churchSlug  = "church_slug"
          case postId      = "post_id"
          case eventId     = "event_id"
          case isRead      = "is_read"
          case createdAt   = "created_at"
      }
  }

  struct Comment: Codable, Identifiable {
      let id: UUID
      let postId: UUID
      let userId: UUID
      let authorName: String
      let authorType: String
      let authorPhotoUrl: String?
      let content: String
      let createdAt: Date

      enum CodingKeys: String, CodingKey {
          case id, content
          case postId         = "post_id"
          case userId         = "user_id"
          case authorName     = "author_name"
          case authorType     = "author_type"
          case authorPhotoUrl = "author_photo_url"
          case createdAt      = "created_at"
      }
  }

  // MARK: - UI Helpers

  /// UI representation of a follower/following with resolved metadata.
  struct FollowEntry: Identifiable {
      let id: UUID
      let displayName: String
      let photoUrl: String?
      let subtitle: String?
  }

  // MARK: - Structured schedule
  //
  // Mirrors the web stack's `service_times_json` (array of ServiceTime) and
  // `office_hours_json` (week object) shapes. Stored as JSONB on
  // `church_submissions`. Source of truth: src/lib/schedule.ts in lcn-web.

  enum DayOfWeek: String, Codable, CaseIterable {
      case sunday, monday, tuesday, wednesday, thursday, friday, saturday

      var label: String {
          switch self {
          case .sunday:    return "Sunday"
          case .monday:    return "Monday"
          case .tuesday:   return "Tuesday"
          case .wednesday: return "Wednesday"
          case .thursday:  return "Thursday"
          case .friday:    return "Friday"
          case .saturday:  return "Saturday"
          }
      }

      var shortLabel: String {
          switch self {
          case .sunday:    return "Sun"
          case .monday:    return "Mon"
          case .tuesday:   return "Tue"
          case .wednesday: return "Wed"
          case .thursday:  return "Thu"
          case .friday:    return "Fri"
          case .saturday:  return "Sat"
          }
      }
  }

  struct ServiceTime: Codable, Identifiable, Hashable {
      let id: String
      var serviceType: String   // "Sunday Service", "Bible Study", etc.
      var day: DayOfWeek
      var startTime: String     // "HH:mm" 24-hour
      var endTime: String       // "HH:mm" 24-hour
      var language: String      // "English", etc.
      var livestream: Bool
  }

  struct OfficeHoursDay: Codable, Hashable {
      var isOpen: Bool
      var open: String?         // "HH:mm" or nil when closed
      var close: String?
  }

  struct OfficeHours: Codable, Hashable {
      var byAppointmentOnly: Bool
      var schedule: [String: OfficeHoursDay]  // keyed by DayOfWeek.rawValue
  }

  // Weekly livestream schedule. Mirrors the web stack's
  // `livestream_schedule_json` shape — distinct from `service_times_json`
  // (in-person services) so a church can declare "we go live online
  // during these windows" independently of physical service times.
  struct LivestreamScheduleDay: Codable, Hashable {
      var isLive: Bool
      var start: String?        // "HH:mm" or nil when off air
      var end: String?
  }

  struct LivestreamSchedule: Codable, Hashable {
      var schedule: [String: LivestreamScheduleDay]  // keyed by DayOfWeek.rawValue
  }

  // MARK: - Trust & Safety

  /// Reasons a user can flag content. Mirrors the web FlagReason union.
  enum FlagReason: String, CaseIterable, Codable {
      case spam
      case harassment
      case hateSpeech     = "hate_speech"
      case inappropriate
      case misinformation
      case other

      var label: String {
          switch self {
          case .spam:           return "Spam"
          case .harassment:     return "Harassment or bullying"
          case .hateSpeech:     return "Hate speech"
          case .inappropriate:  return "Inappropriate content"
          case .misinformation: return "Misleading information"
          case .other:          return "Something else"
          }
      }

      var helper: String {
          switch self {
          case .spam:           return "Repeated, unwanted, or commercial content."
          case .harassment:     return "Targeting someone with insults or threats."
          case .hateSpeech:     return "Attacks based on identity, religion, race, etc."
          case .inappropriate:  return "Sexual, violent, or shocking content."
          case .misinformation: return "Knowingly false or harmful claims."
          case .other:          return "Use the notes field to explain."
          }
      }
  }

  /// What's being flagged. Matches `flagged_content.content_type`.
  enum FlagContentType: String, Codable {
      case post, comment, profile, church
  }

  struct UserBlock: Codable {
      let blockerId: UUID
      let blockedId: UUID
      let reason: String?
      let createdAt: Date

      enum CodingKeys: String, CodingKey {
          case reason
          case blockerId  = "blocker_id"
          case blockedId  = "blocked_id"
          case createdAt  = "created_at"
      }
  }

  struct HiddenPost: Codable {
      let userId: UUID
      let postId: UUID
      let createdAt: Date

      enum CodingKeys: String, CodingKey {
          case userId    = "user_id"
          case postId    = "post_id"
          case createdAt = "created_at"
      }
  }

  /// Per-category notification opt-outs. Mirrors the columns on
  /// `notification_preferences`. The DB-side trigger on `notifications`
  /// INSERT consults these — turning a flag off here means the
  /// recipient never sees that notification, full stop.
  struct NotificationPreferences: Codable {
      var newFollowers:    Bool
      var newLikes:        Bool
      var newComments:     Bool
      var prayerResponses: Bool
      var churchUpdates:   Bool
      var churchLive:      Bool
      var inquiryReplies:  Bool
      var newInquiries:    Bool
      /// Master switch — when false, every category is suppressed.
      var pushEnabled:     Bool

      static let defaults = NotificationPreferences(
          newFollowers:    true,
          newLikes:        true,
          newComments:     true,
          prayerResponses: true,
          churchUpdates:   true,
          churchLive:      true,
          inquiryReplies:  true,
          newInquiries:    true,
          pushEnabled:     true,
      )

      enum CodingKeys: String, CodingKey {
          case newFollowers    = "new_followers"
          case newLikes        = "new_likes"
          case newComments     = "new_comments"
          case prayerResponses = "prayer_responses"
          case churchUpdates   = "church_updates"
          case churchLive      = "church_live"
          case inquiryReplies  = "inquiry_replies"
          case newInquiries    = "new_inquiries"
          case pushEnabled     = "push_enabled"
      }
  }

  /// Display row for the Blocked Accounts management screen — already
  /// joined against profiles + church_submissions so the view can render
  /// without further roundtrips.
  struct BlockedEntry: Identifiable {
      let blockedId: UUID
      let name: String
      let photoUrl: String?
      let kind: Kind
      /// Church slug when `.church`; nil for people (use blockedId).
      let slug: String?
      let reason: String?
      let blockedAt: Date

      var id: UUID { blockedId }

      enum Kind { case person, church }
  }

