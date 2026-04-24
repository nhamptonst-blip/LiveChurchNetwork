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

  struct Church: Identifiable, Equatable {
      let id = UUID()
      let name: String
      let slug: String
      let image: String
      let denomination: String
      let permalink: String
      let phone: String
      let email: String = ""
      let address: String = ""
      let website: String
      let donationUrl: String = ""
      let serviceTimes: String
      let about: String
      var isLive: Bool = false
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

      var activityPrivacy:  PrivacySetting { PrivacySetting(rawValue: activityVisibility  ?? "") ?? .public }
      var followersPrivacy: PrivacySetting { PrivacySetting(rawValue: followersVisibility ?? "") ?? .public }
      var followingPrivacy: PrivacySetting { PrivacySetting(rawValue: followingVisibility ?? "") ?? .public }
      var churchesPrivacy:  PrivacySetting { PrivacySetting(rawValue: churchesVisibility  ?? "") ?? .public }

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
      // Privacy settings — what this user has chosen to share with others.
      var activityPrivacy:  PrivacySetting = .public
      var followersPrivacy: PrivacySetting = .public
      var followingPrivacy: PrivacySetting = .public
      var churchesPrivacy:  PrivacySetting = .public
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

      var inquiryType: InquiryType  { InquiryType(rawValue: type)     ?? .general }
      var inquiryStatus: InquiryStatus { InquiryStatus(rawValue: status) ?? .new }

      enum CodingKeys: String, CodingKey {
          case id, type, subject, body, status
          case memberId   = "member_id"
          case memberName = "member_name"
          case churchSlug = "church_slug"
          case churchName = "church_name"
          case createdAt  = "created_at"
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
          case officeHours     = "office_hours"
          case leadershipTeam  = "leadership_team"
          case ministries
          case podcastUrl      = "podcast_url"
          case livestreamUrl   = "livestream_url"
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
      let content: String?
      let photoUrl: String?
      let videoUrl: String?
      let postType: String
      var likeCount: Int
      var isImportant: Bool = false
      var isPinned: Bool = false
      var sendNotification: Bool = false
      var highlightInFeed: Bool = false
      let createdAt: Date
      var isLiked: Bool = false

      enum CodingKeys: String, CodingKey {
          case id, content
          case authorId   = "author_id"
          case authorName = "author_name"
          case authorType = "author_type"
          case photoUrl   = "photo_url"
          case videoUrl   = "video_url"
          case postType   = "post_type"
          case likeCount  = "like_count"
          case isImportant = "is_important"
          case isPinned = "is_pinned"
          case sendNotification = "send_notification"
          case highlightInFeed = "highlight_in_feed"
          case createdAt  = "created_at"
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

