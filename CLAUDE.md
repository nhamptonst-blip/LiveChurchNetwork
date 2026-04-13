# Live Church Network — CLAUDE.md

Complete reference for building and extending this app. Read this before writing any code.

---

## What This App Is

Live Church Network is an iOS social platform that connects churches and worshippers.
It is a **hybrid of a social network and a church directory** — not just a directory, and not just a social feed.

Two distinct audiences use the app for opposite purposes:
- **Worshippers** come to discover, follow, and engage with churches
- **Churches** come to create a presence, publish content, and reach people

Every design decision should reflect this duality.

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 16+) |
| State | `ObservableObject` + `@Published` via `AppState` |
| Backend | Supabase (auth, database, storage) |
| Realtime | Not yet implemented |
| Images | Supabase Storage (`avatars`, `covers` buckets) |
| Local persistence | `UserDefaults` + `@AppStorage` |

**Supabase project:** `hjckwtjzvuacpckqsasa.supabase.co`

---

## Project Structure

```
LiveChurchNetwork/
├── LiveChurchNetworkApp.swift     — App entry point, injects AppState
├── AppState.swift                  — Central auth + routing state
├── ContentView.swift               — Root router (auth → onboarding → main)
├── Models.swift                    — All data models (Profile, Post, Event, etc.)
├── BrandColors.swift               — All Color + UIColor brand extensions
├── SupabaseService.swift           — All Supabase API calls (singleton)
├── MockData.swift / MockSeedData.swift / ChurchesData.swift — Fallback data
│
├── Auth
│   ├── AuthView.swift              — Login screen (entry point for new users)
│
├── Onboarding
│   ├── ProfileOnboardingView.swift — Worshipper post-signup onboarding (3 steps)
│   └── ChurchOnboardingView.swift  — Church post-signup onboarding (6 steps)
│
├── Main Tabs
│   ├── HomeView.swift              — Feed tab wrapper / hero section
│   ├── FeedView.swift              — Main social feed (posts + events)
│   ├── DirectoryView.swift         — Church discovery / search
│   └── NotificationsView.swift     — Notification center
│
├── Dashboards (Profile tab, role-gated)
│   ├── WorkshipperDashboardView.swift
│   ├── ChurchAdminDashboardView.swift
│   └── AdminDashboardView.swift
│
├── Church
│   ├── ChurchDetailView.swift      — Church profile page (Home/About/Events/Media tabs)
│   ├── ChurchContactView.swift     — Inquiry form (sheet)
│   └── ChurchInboxView.swift       — Admin inbox for inquiries
│
├── Shared
│   ├── PostCard.swift
│   ├── ChurchCard.swift
│   ├── UserAvatarView.swift
│   ├── FollowButton.swift
│   ├── CreatePostView.swift
│   └── RecommendationEngine.swift
│
└── Assets.xcassets/
    ├── AppLogo.imageset/           — Official LCN logo (Logo.png)
    └── AppIcon.appiconset/
```

---

## User Roles (Ontology)

There are exactly three roles in the system. Role is stored in `profiles.role`.

### `worshipper`
- Default role for regular users
- Browses the directory, follows churches and people
- Has a personal profile, posts, activity feed
- Onboarding: `ProfileOnboardingView` (3 steps: profile setup → follow churches → follow people)
- Dashboard: `WorkshipperDashboardView`

### `church_admin`
- Represents an organization (a church), not an individual
- Creates and manages a church page, publishes posts + events
- Cannot follow other churches or users in the worshipper sense
- Onboarding: `ChurchOnboardingView` (6 steps: welcome → basic info → branding → services → about & giving → first content)
- Dashboard: `ChurchAdminDashboardView`
- Has a linked `church_submissions` row (created automatically at signup)

### `admin`
- Platform administrator
- Dashboard: `AdminDashboardView`
- Manages church submission approvals

---

## App Navigation Flow

```
App Launch
    │
    ├── Session found → SplashView (brief) → MainTabView
    │
    └── No session → AuthView
            │
            ├── Sign In → MainTabView
            │
            └── Register (role selection built in)
                    │
                    ├── worshipper → ProfileOnboardingView → MainTabView
                    └── church_admin → ChurchOnboardingView → MainTabView
```

### MainTabView (authenticated)
```
Tab 1: Feed          — FeedView
Tab 2: Discover      — DirectoryView
Tab 3: Notifications — NotificationsView
Tab 4: Profile       — WorkshipperDashboardView
                        OR ChurchAdminDashboardView
                        OR AdminDashboardView
```

---

## Routing Logic (`AppState`)

`AppState` is the single source of truth for navigation state.

| Property | Type | Meaning |
|---|---|---|
| `isAuthenticated` | Bool | Valid Supabase session exists |
| `isGuest` | Bool | Guest mode (no account) |
| `isLoading` | Bool | Session check in progress |
| `needsProfileOnboarding` | Bool | New worshipper, hasn't completed onboarding |
| `needsChurchOnboarding` | Bool | New church admin, hasn't completed onboarding |
| `profile` | `Profile?` | Loaded profile row from Supabase |
| `currentUserId` | `UUID?` | Auth user ID |

`ContentView` routes based on this state in priority order:
1. `isLoading` → `SplashView`
2. `needsChurchOnboarding` → `ChurchOnboardingView`
3. `needsProfileOnboarding` → `ProfileOnboardingView`
4. `isAuthenticated || isGuest` → `MainTabView`
5. else → `AuthView`

### Onboarding completion keys (UserDefaults)
```
profileOnboarding_complete_{userId}    → true when worshipper done
churchOnboarding_complete_{userId}     → true when church done
churchOnboarding_step_{userId}         → int, resume step for church flow
```

---

## Database Schema (Supabase)

### `profiles`
```
id              uuid pk (matches auth.users.id)
full_name       text
role            text   — 'worshipper' | 'church_admin' | 'admin'
bio             text
city            text
denomination    text
languages       text
photo_url       text
cover_url       text
activity_visibility   text default 'public'
followers_visibility  text default 'public'
following_visibility  text default 'public'
churches_visibility   text default 'public'
```

### `church_submissions`
The church profile record. Created automatically on church_admin signup.
```
id              uuid pk
user_id         uuid → profiles.id
church_name     text
denomination    text
phone           text
website         text
service_times   text
about           text        — used for description, what to expect, donation link, livestream
is_live         bool default false
status          text        — 'pending' | 'approved' | 'rejected'
```

### `posts`
```
id              uuid pk
author_id       uuid → profiles.id
author_name     text
author_type     text   — 'worshipper' | 'church'
content         text
photo_url       text
video_url       text
post_type       text   — 'update' | 'announcement' | 'livestream'
like_count      int default 0
created_at      timestamptz
```

### `events`
```
id              uuid pk
author_id       uuid → profiles.id
author_name     text
title           text
description     text
event_date      timestamptz
location        text
created_at      timestamptz
```

### `follows`
```
id              uuid pk
follower_id     uuid → profiles.id
following_id    text        — either a profile UUID or a church slug
following_type  text        — 'worshipper' | 'church'
created_at      timestamptz
```

### `likes`
```
id              uuid pk
user_id         uuid → profiles.id
post_id         uuid → posts.id
created_at      timestamptz
```

### `notifications`
```
id              uuid pk
user_id         uuid
type            text   — see notification types below
title           text
body            text
related_id      uuid
actor_user_id   uuid
church_slug     text
post_id         uuid
event_id        uuid
is_read         bool default false
created_at      timestamptz
```
Notification types: `new_follower`, `new_like`, `church_live`, `new_post`, `new_event`, `church_inquiry_reply`

### `church_inquiries`
```
id              uuid pk
member_id       uuid → profiles.id
member_name     text
church_slug     text
church_name     text
type            text   — 'general' | 'prayer' | 'visit' | 'volunteer' | 'event'
subject         text
body            text
status          text default 'new'   — 'new' | 'replied' | 'archived'
created_at      timestamptz
```

### `saved_churches`
```
id              uuid pk
user_id         uuid → profiles.id
church_slug     text
```

### Supabase Storage Buckets
```
avatars    — profile photos and church logos (path: {userId}/avatar.jpg)
covers     — cover photos (path: {userId}/cover.jpg)
```

---

## `Church` Model (Static Directory)

The `Church` struct in `ChurchesData.swift` represents static directory data (not from DB).
These are pre-seeded churches used for discovery.

```swift
struct Church: Identifiable {
    let id: UUID
    let name: String
    let slug: String          // unique identifier used in follows/notifications
    let image: String         // URL
    let denomination: String
    let permalink: String     // external URL
    let phone: String
    let email: String
    let address: String
    let website: String
    let donationUrl: String
    let serviceTimes: String
    let about: String
    var isLive: Bool
}
```

`CHURCHES` is the global array of all static church data, defined in `ChurchesData.swift`.

---

## Mock Data Pattern

**Always prefer real Supabase data. Fall back to mock data when real data is empty.**

```swift
let loaded = (try? await SupabaseService.shared.getSomething()) ?? []
let data = loaded.isEmpty ? MockDataProvider.something() : loaded
```

`MockDataProvider` in `MockData.swift` provides:
- `posts(forChurch:)` — sample posts for a church
- `events(forChurch:)` — sample events
- `leaders(forChurch:)` — leadership profiles
- `followerCount(forSlug:)` — fallback follower count
- `allSeedUsers` — discoverable worshipper accounts

---

## Brand Identity

### Colors
```swift
.lcNavy      #1F3C88  — primary brand, buttons, headers
.lcNavyDark  #162D6A  — gradients, dark variant
.lcGold      #F0A500  — accent, highlights, CTA
.lcGoldLight #FFF8E7  — gold tint backgrounds
.lcTeal      #5B8FA8  — secondary accent, success states
.lcCream     #FAF8F5  — app background (never pure white)
.lcText      #161616  — primary text (near-black)
.lcText2     #3E3E48  — secondary text
.lcText3     #80808C  — muted text, placeholders
.lcBorder    #E2DED8  — dividers, input borders
```

### Logo
`Image("AppLogo")` — located at `Assets.xcassets/AppLogo.imageset/Logo.png`

Use on light backgrounds. For dark (navy gradient) backgrounds, place in a rounded white card.

### Typography
All text uses `.system` font with weights:
- `.black` — headings, titles
- `.bold` — section labels, button labels
- `.semibold` — sub-labels, badges
- `.medium` — list items
- `.regular` — body text

### Corner Radius Conventions
```
Cards:        14pt
Buttons:      14pt (primary), 20pt (pill/small)
Input fields: 12pt
Logo/images:  16–22pt depending on size
Avatars:      Circle
```

---

## Church Detail View (`ChurchDetailView`)

Church profiles are not user profiles. They have 4 tabs:

| Tab | Content |
|---|---|
| **Home** | Live banner (if streaming) + posts/updates feed |
| **About** | Description, location & contact, service info, online & giving, leadership |
| **Events** | Service schedule + upcoming events |
| **Media** | Livestream embed or latest video posts |

Action strip (horizontal scroll): **Watch Live** · **Get Directions** · **Give** · **Contact**

The `ChurchProfileTab` enum: `.home`, `.about`, `.events`, `.media`

---

## Church Onboarding (`ChurchOnboardingView`)

6 steps + completion. Progress saved to UserDefaults.

| Step | Purpose |
|---|---|
| 0 | Welcome — sets expectations, previews steps ahead |
| 1 | Basic Info — name (pre-filled), denomination, city, address, website, phone, email |
| 2 | Branding — logo upload, cover photo upload, previews |
| 3 | Services + Livestream — service times textarea, livestream toggle + URL |
| 4 | About + Contact + Giving — description, what to expect, languages, donation link |
| 5 | First Content — segmented: Post (free text) OR Event (title, date, location) |
| ✓ | Completion — "Your church is now live!" → Dashboard or Profile |

**Rules:**
- Church name pre-filled from `appState.profile?.fullName` (set during registration)
- All steps skippable, but content step is strongly encouraged
- After completion: `UserDefaults["churchOnboarding_complete_{userId}"] = true`

---

## Worshipper Onboarding (`ProfileOnboardingView`)

3 steps + completion. Shown only to `worshipper` role.

| Step | Purpose |
|---|---|
| 0 | Profile Setup — bio, city, denomination |
| 1 | Follow Churches — suggest up to 10 churches |
| 2 | Follow People — suggest up to 8 seed users |
| ✓ | Completion — stats summary + "Go to Feed" |

**Never show this to church_admin.** That role goes to `ChurchOnboardingView`.

---

## Registration Flow (`AuthView` → `RegisterView`)

`AuthView` is the **entry point for all unauthenticated users**.
Returning users auto-login via `AppState.checkSession()` (no login screen shown).

`RegisterView` has two account type cards:
- **"I'm a Member"** → `role = "worshipper"`
- **"I Represent a Church"** → `role = "church_admin"`, shows church-specific fields

Church fields: Church Name, Your Name (Contact), Email, Password, Denomination (optional), City (optional)

**Critical timing fix:** After `SupabaseService.signUp()` completes (profile INSERT done), `RegisterView` calls `await appState.loadProfile()` to ensure correct role-based routing. Without this, the Supabase auth event fires before the profile row exists, causing wrong onboarding routing.

---

## `SupabaseService` — Key Methods

All calls go through `SupabaseService.shared` (singleton).

```swift
// Auth
signIn(email:password:)
signUp(email:password:fullName:role:bio:city:denomination:)
signOut()

// Profiles
getProfile(userId:) → Profile?
updateProfile(userId:fullName:city:denomination:bio:)
updateProfilePhotoUrl(userId:photoUrl:)
updateProfileCoverUrl(userId:coverUrl:)
uploadProfileImage(userId:data:bucket:) → String (URL)

// Church submissions
getChurchSubmission(userId:) → ChurchSubmission?
getOrCreateChurchSubmission(userId:churchName:) → ChurchSubmission
updateChurchProfile(submissionId:churchName:denomination:phone:website:serviceTimes:about:)
updateLiveStatus(submissionId:isLive:)

// Posts
getFeedPosts() → [Post]
getPostsByAuthor(authorName:) → [Post]
createPost(authorId:authorName:authorType:content:photoUrl:videoUrl:postType:)
toggleLike(userId:postId:currentlyLiked:currentCount:)
getLikedPostIds(userId:) → Set<UUID>

// Events
getUpcomingEvents() → [Event]
getEventsByAuthor(authorName:) → [Event]
createEvent(authorId:authorName:title:description:eventDate:location:)

// Follows
follow(followerId:followingId:followingType:)
unfollow(followerId:followingId:)
isFollowingChurch(followerId:churchSlug:) → Bool
getFollowing(followerId:) → [Follow]
getFollowers(userId:) → [Follow]
getFollowerCount(followingId:) → Int

// Notifications
getNotifications(userId:) → [AppNotification]
markNotificationRead(id:)

// Inquiries
getInquiries(churchName:) → [ChurchInquiry]
submitInquiry(memberId:memberName:churchSlug:churchName:type:subject:body:)
updateInquiryStatus(id:status:)

// Saved churches
getSavedChurches(userId:) → [SavedChurch]
saveChurch(userId:churchSlug:)
unsaveChurch(userId:churchSlug:)
```

---

## Important Rules & Patterns

### Church vs. Worshipper Language
| Worshipper | Church |
|---|---|
| Discover | Be discovered |
| Follow | Reach people |
| Connect | Build your community |
| Explore | Set up / publish |

Never mix these. Church onboarding never mentions following churches or people.

### Empty States
All empty states should have:
1. An SF Symbol icon (dimmed, medium size)
2. A bold title (e.g. "No posts yet")
3. A subtitle that is role-appropriate

Church empty states encourage publishing. Worshipper empty states encourage discovery.

### Supabase Error Handling
Use `try?` for non-critical operations (likes, follows, secondary saves).
Use `try/catch` with user-visible error messages for critical operations (signup, profile creation).
Always provide mock fallback data when real data returns empty.

### Image Upload Pattern
```swift
// Compress before upload
let compressed = UIImage(data: data)?.jpegData(compressionQuality: 0.75)
// Upload to bucket, get URL back
let url = try? await SupabaseService.shared.uploadProfileImage(userId:, data:, bucket:)
// Persist URL to profile
try? await SupabaseService.shared.updateProfilePhotoUrl(userId:, photoUrl: url)
```

### `@AppStorage` Keys
```
hasSeenOnboarding            — DEPRECATED, no longer used
preSelectedRole              — 'worshipper' | 'church_admin' (from registration)
profileOnboarding_complete_* — per-user worshipper onboarding flag
churchOnboarding_complete_*  — per-user church onboarding flag
churchOnboarding_step_*      — per-user church onboarding resume step
```

### Privacy Settings
Profiles have four visibility toggles stored as strings: `'public'` | `'followers_only'` | `'private'`
- `activity_visibility`
- `followers_visibility`
- `following_visibility`
- `churches_visibility`

Handled by `PrivacySetting` enum and `PrivacySettingsView`.

---

## Things That Don't Exist Yet (Future Work)

- Real-time notifications (Supabase realtime / push)
- Church `email` and `donationUrl` as dedicated DB columns (currently stored in `about` text)
- Sermon/media library
- In-app livestream player (currently opens external URL)
- Search across posts and people
- Direct messages between churches and members
- Church analytics dashboard
- Admin approval flow for new church submissions

---

## File Naming Conventions

- Views: `{Feature}View.swift` (e.g. `ChurchDetailView.swift`)
- Dashboards: `{Role}DashboardView.swift`
- Onboarding: `{Role}OnboardingView.swift`
- Models: all in `Models.swift`
- Static data: `{Domain}Data.swift` (e.g. `ChurchesData.swift`)
- Mock: `MockData.swift`, `MockSeedData.swift`
