# App Store Submission Packet — Live Church Network

Last reviewed: 2026-05-09. Update this whenever app behavior, data
collection, or marketing copy changes.

---

## 1. App Store Connect metadata

Drop these strings directly into App Store Connect → App Store → App
Information / Version. Lengths shown are Apple's hard limits.

### Name (max 30)

```
Live Church Network
```

### Subtitle (max 30)

```
Find your church. Stay close.
```

### Promotional Text (max 170, can update without resubmitting)

```
Discover churches near you, follow ministries you love, watch services live, share prayer requests with your community, and stay connected to your faith — wherever you are.
```

### Description (max 4000)

```
Live Church Network is the social home for worshippers and churches.

DISCOVER YOUR CHURCH
• Browse churches near you by city, denomination, language, and live service times
• Watch livestreams the moment a service begins — the LIVE badge lights up automatically
• Read sermons, follow ministries, and find the right faith community for your season

ENGAGE YOUR COMMUNITY
• Share prayer requests, testimonies, and life updates with people who care
• Pray for posts, comment, and RSVP to events with one tap
• Send a private inquiry to a church about visiting, volunteering, or joining a small group

FOR CHURCHES
• Reach members where they already are — phone in hand, throughout the week
• Publish posts and events, go live for special services, and reply directly to member inquiries
• See who's engaging with your content through real-time analytics
• Add your weekly schedule once and the LIVE badge auto-activates during service hours

SAFE & RESPECTFUL
• Report or block any account
• Hide individual posts you don't want to see
• Privacy controls for activity, follows, and church affiliation

Live Church Network is free for worshippers. Churches join free and stay free.
```

### Keywords (max 100 chars, comma-separated, no spaces)

```
church,worship,prayer,sermon,livestream,faith,christian,community,bible,ministry,pastor,fellowship
```

### Support URL

```
https://www.livechurchnetwork.com/support
```

### Marketing URL (optional)

```
https://www.livechurchnetwork.com
```

### Privacy Policy URL

```
https://www.livechurchnetwork.com/privacy
```

### Copyright

```
© 2026 Live Church Network
```

### Category

- Primary: **Lifestyle**
- Secondary: **Social Networking**

### Age Rating

- **4+** — no objectionable content. The 6 quiz questions: all "None".
  - Cartoon or Fantasy Violence: None
  - Realistic Violence: None
  - Sexual Content or Nudity: None
  - Profanity or Crude Humor: None
  - Alcohol, Tobacco, or Drug Use: None
  - Mature/Suggestive Themes: None
  - Horror/Fear Themes: None
  - Medical/Treatment Information: None
  - Gambling: None
  - Unrestricted Web Access: **Yes** (livestream URLs route to YouTube/etc.)
  - User-Generated Content: **Yes** (this triggers an extra moderation
    questionnaire — see below).

### User-generated content questionnaire

Apple asks because we have UGC. Answer:

- **A method for filtering objectionable material**: Yes
  - Reports go to `flagged_content` table; admins review at `/admin/reports`.
- **A mechanism for users to report and block other users**: Yes
  - Three-dot menu on any post / profile / comment.
- **The ability to block abusive users**: Yes
  - `user_blocks` table, viewable + manageable in Profile → Privacy → Blocked Accounts.
- **A published method for contacting the developer**: Yes
  - support@livechurchnetwork.com, listed at /support and in app Settings.

### What's New (per release, max 4000)

For 1.0.0:

```
We're thrilled to launch Live Church Network — a home for worshippers and churches to connect, share, and grow together.

• Discover churches near you with live service times and watch streams
• Share prayer requests and read responses from your community
• Follow churches and people; reply privately to a church
• Built-in safety: report, block, and hide whatever you need to
```

---

## 2. App Privacy questionnaire (App Store Connect → App Privacy)

These answers must match `LiveChurchNetwork/PrivacyInfo.xcprivacy`. If
the manifest changes, update this section too.

### Data collected

| Category                   | Linked? | Used for tracking? | Purpose(s) |
|----------------------------|---------|--------------------|------------|
| Email Address              | Yes     | No                 | App Functionality, Customer Support |
| Name                       | Yes     | No                 | App Functionality |
| Coarse Location (city)     | Yes     | No                 | App Functionality, Personalization |
| Photos or Videos           | Yes     | No                 | App Functionality |
| Other User Content (posts, comments, prayers, inquiries) | Yes | No | App Functionality |
| User ID (Supabase auth ID) | Yes     | No                 | App Functionality |
| Other Diagnostic Data (push tokens, error logs) | Yes | No | App Functionality, Analytics |

### Tracking

- **Does this app track users?** No. We do not link user data to data from
  other companies' apps or websites for advertising or sharing with data
  brokers. The Sentry / push-token data is collected for product
  functionality and crash reporting only.

### Third-party data

Disclose:
- **Supabase** — backend, hosts every category above.
- **Sentry** — error monitoring (Other Diagnostic Data only).
- **Apple Push Notification service (APNs)** — push delivery.

---

## 3. Screenshots checklist

Apple requires:
- **6.7" iPhone (iPhone 15 Pro Max)** — 1290×2796 px, at least 3 screenshots, max 10
- **6.5" iPhone (iPhone 14 Plus)** — 1242×2688 or 1284×2778 px (optional but
  recommended for older devices)
- **iPad Pro 12.9" (6th gen)** — 2048×2732 px (only if you ship iPad support)

### Suggested screenshot order

1. **Discover** — directory page with map view, captioned
   *"Find your church near you"*.
2. **Live Now** — feed showing a live church banner, captioned
   *"Watch services the moment they go live"*.
3. **Prayer feed** — prayer post with several "🙏 Praying" responders,
   captioned *"Pray for someone today"*.
4. **Church profile** — Welcome panel + service times, captioned
   *"Everything about a church in one place"*.
5. **Church admin dashboard** — KPI cards + recent activity, captioned
   *"Reach your members all week long"*.

Use real-looking content — no Lorem Ipsum, no placeholder names. Run
through the AI worshipper seed once before screenshotting if needed.

---

## 4. Pre-flight checklist

Before tapping "Submit for Review":

- [ ] `PrivacyInfo.xcprivacy` is included in the app target's Compile
      Sources (Xcode → Build Phases → Copy Bundle Resources).
- [ ] App Store Connect → App Privacy filled out to match Section 2.
- [ ] Sign in with Apple capability enabled (Xcode → Signing & Capabilities).
- [ ] Push Notifications capability enabled.
- [ ] Apple Developer → Identifiers → app's Bundle ID has Sign in with
      Apple checked.
- [ ] Supabase Auth → Apple provider configured with Service ID, Team
      ID, Key ID, and `.p8` private key.
- [ ] Test sign-up + sign-in (password, magic link, Apple) on a clean
      install.
- [ ] Test reporting a post and confirming it appears in the admin
      moderation queue.
- [ ] Test blocking and unblocking from the Privacy → Blocked Accounts
      screen.
- [ ] Verify the Support URL loads when tapped from the App Store
      preview.
- [ ] Verify push notifications deliver from the live `/api/push/send`
      endpoint to a real device.
- [ ] All five required screenshots uploaded for 6.7" iPhone.
- [ ] App icon present in Xcode at every required size.
- [ ] `What's New` text written.
- [ ] Build number bumped (`CURRENT_PROJECT_VERSION` in Xcode).
- [ ] Demo account credentials in App Review Information (Apple needs
      to log in to test) — create a `demo@livechurchnetwork.com`
      worshipper account with a populated feed.

---

## 5. Common rejection reasons we've already addressed

| Reason                                            | Status |
|---------------------------------------------------|--------|
| Guideline 1.2 — UGC moderation                    | ✅ Report/block/hide on posts, comments, profiles, churches; admin queue |
| Guideline 4.8 — third-party auth requires Apple   | ✅ Sign in with Apple wired |
| Guideline 5.1.1 — Account deletion                | ⚠️ Currently email-based; add an in-app "Delete Account" flow before submitting |
| ITMS-91056 — Privacy manifest                     | ✅ `PrivacyInfo.xcprivacy` included |
| Guideline 5.1.4 — Kid Category data collection    | N/A (4+ but not Kids Category) |
| Guideline 1.1.6 — Inaccurate descriptions         | ✅ Description matches features |
| Guideline 2.3.10 — Apple branding accuracy        | ✅ Sign in with Apple uses official `SignInWithAppleButton` |

The one remaining gap is **in-app account deletion** — Apple's 2022 rule
requires accounts be deletable from inside the app, not only via email.
Build a `DeleteAccountView` that calls a service-role Edge Function to
hard-delete the auth user + all owned rows before submitting.

---

## 6. Demo account

Create before submission:

```
Email:    demo@livechurchnetwork.com
Password: <use a strong password and write it in App Review Info>
City:     Nashville
Denomination: Non-Denominational
```

Pre-follow ~10 churches, like a few posts, send one inquiry. Reviewers
need to see a populated experience, not an empty feed.
