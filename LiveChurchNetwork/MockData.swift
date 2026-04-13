import Foundation

// MARK: - Mock Data Provider
//
// Central demo/development data layer.
// Views call these fallbacks when real backend data is empty.
// To disable demo mode, set MockDataProvider.enabled = false.

enum MockDataProvider {

    static var enabled = true

    // MARK: - Worshipper profile

    /// Follower count shown on the demo user profile
    static let worshipperFollowerCount = 47
    static let worshipperFollowingCount = 12

    /// Church slugs the demo user follows (must match slugs in ChurchesData.swift)
    static let followedChurchSlugs = [
        "grace-community-church",
        "unity-methodist-church",
        "hillsong-church-los-angeles"
    ]

    /// Events shown on the demo user's Events tab
    static var worshipperEvents: [Event] {
        guard enabled else { return [] }
        return [
            makeEvent(
                authorName: "Grace Community Church",
                title: "Sunday Worship Service",
                description: "Join us for an uplifting Sunday morning worship experience.",
                daysFromNow: 3,
                location: "123 Grace Ave, Atlanta, GA"
            ),
            makeEvent(
                authorName: "Unity Methodist Church",
                title: "Wednesday Bible Study",
                description: "Deep dive into the book of Romans with Pastor James.",
                daysFromNow: 6,
                location: "Unity Methodist Church, Main Hall"
            ),
            makeEvent(
                authorName: "Hillsong Church Los Angeles",
                title: "Youth Night",
                description: "An energetic night of worship, games, and community for teens and young adults.",
                daysFromNow: 9,
                location: "Hillsong LA, Youth Center"
            )
        ]
    }

    // MARK: - Church posts

    /// Returns a realistic set of demo posts for the given church.
    /// Rotates through content templates so each church feels unique.
    static func posts(forChurch churchName: String) -> [Post] {
        guard enabled else { return [] }

        // Use a stable hash of the church name to vary which templates appear first
        let seed = abs(churchName.hashValue) % 3
        let authorId = deterministicUUID(for: churchName)

        let allTemplates: [(content: String?, photoUrl: String?, videoUrl: String?, type: String, hoursAgo: Int, likes: Int)] = [
            // Livestream post
            (
                "Join us LIVE right now for Sunday Morning Worship! We are streaming from \(churchName). Watch from anywhere — all are welcome. 🙏",
                nil,
                "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
                "livestream",
                1,
                84
            ),
            // Sunday reminder
            (
                "This Sunday we continue our series on the book of Acts. Doors open at 9:30 AM — bring a friend, bring your Bible, and come ready to encounter God. See you there!",
                nil,
                nil,
                "update",
                18,
                62
            ),
            // Bible study announcement
            (
                "Wednesday Bible Study is tonight at 7 PM! We're going through the Gospel of John. Come ready to ask questions and grow. All are welcome — no prior experience needed.",
                nil,
                nil,
                "update",
                48,
                41
            ),
            // Event post
            (
                "YOUTH NIGHT this Friday at 6:30 PM! 🎉 Games, worship, testimony, and a powerful message. If you have teens in your life, bring them along. It's going to be an incredible night.",
                nil,
                nil,
                "event",
                72,
                58
            ),
            // Community outreach
            (
                "This Saturday we're heading into the community for our monthly outreach. Meet at the church at 9 AM. Bring work gloves and a servant's heart — let's be the hands and feet of Jesus together. 💪",
                nil,
                nil,
                "update",
                96,
                29
            ),
            // Scripture encouragement
            (
                "\"For I know the plans I have for you,\" declares the LORD, \"plans to prosper you and not to harm you, plans to give you hope and a future.\" — Jeremiah 29:11\n\nHave a blessed week, \(churchName) family. 🙏",
                nil,
                nil,
                "update",
                120,
                113
            ),
            // Prayer gathering
            (
                "Prayer Gathering this Thursday evening at 6 PM in the Chapel. Come as you are. We will be spending an hour together in intercession and worship. No agenda — just Jesus.",
                nil,
                nil,
                "update",
                144,
                37
            ),
            // Sermon replay
            (
                "Missed last Sunday? Watch the full sermon replay here! Pastor shared from Romans 8 on the power of the Holy Spirit. One of our most requested messages this year.",
                nil,
                "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
                "update",
                168,
                76
            )
        ]

        // Rotate starting position based on church name
        let rotated = Array(allTemplates.dropFirst(seed)) + Array(allTemplates.prefix(seed))

        return rotated.enumerated().map { i, t in
            makePost(
                authorId: authorId,
                authorName: churchName,
                authorType: "church",
                content: t.content,
                photoUrl: t.photoUrl,
                videoUrl: t.videoUrl,
                postType: t.type,
                hoursAgo: t.hoursAgo,
                likeCount: t.likes,
                index: i
            )
        }
    }

    // MARK: - Feed posts

    /// Mixed feed of church posts + user posts for the main Feed tab.
    static var feedPosts: [Post] {
        guard enabled else { return [] }
        // Combine church posts with top user posts and sort newest first
        let combined = churchFeedPosts + userFeedPosts
        return combined.sorted { $0.createdAt > $1.createdAt }
    }

    private static var churchFeedPosts: [Post] {
        var result: [Post] = []

        result.append(makePost(
            authorId: deterministicUUID(for: "grace-community-church"),
            authorName: "Grace Community Church",
            authorType: "church",
            content: "🔴 We are LIVE right now! Join us for Sunday Morning Worship from anywhere in the world. Tap to watch.",
            photoUrl: nil,
            videoUrl: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            postType: "livestream",
            hoursAgo: 0,
            likeCount: 142,
            index: 0
        ))

        result.append(makePost(
            authorId: deterministicUUID(for: "unity-methodist-church"),
            authorName: "Unity Methodist Church",
            authorType: "church",
            content: "Youth Night is THIS Friday at 6:30 PM! Come join us for worship, community, and a message that will change your life. Bring a friend — all are welcome. 🙏",
            photoUrl: nil,
            videoUrl: nil,
            postType: "event",
            hoursAgo: 3,
            likeCount: 58,
            index: 1
        ))

        result.append(makePost(
            authorId: deterministicUUID(for: "hillsong-church-los-angeles"),
            authorName: "Hillsong Church Los Angeles",
            authorType: "church",
            content: "This Sunday we wrap up our series \"Good Good Father\" with an incredible message on grace. See you at 10 AM and 12 PM! 🎶",
            photoUrl: nil,
            videoUrl: nil,
            postType: "update",
            hoursAgo: 8,
            likeCount: 204,
            index: 2
        ))

        result.append(makePost(
            authorId: deterministicUUID(for: "west-angeles-church-of-god-in-christ"),
            authorName: "West Angeles COGIC",
            authorType: "church",
            content: "Join us Wednesday at 7 PM for Mid-Week Service. The Spirit is moving and you don't want to miss it. In person and online. 🔥",
            photoUrl: nil,
            videoUrl: nil,
            postType: "update",
            hoursAgo: 20,
            likeCount: 97,
            index: 3
        ))

        result.append(makePost(
            authorId: deterministicUUID(for: "grace-community-church"),
            authorName: "Grace Community Church",
            authorType: "church",
            content: "Our community outreach this past Saturday was incredible. Over 80 volunteers showed up to serve our neighbors. This is what the church is for. Thank you to everyone who came out! ❤️",
            photoUrl: nil,
            videoUrl: nil,
            postType: "update",
            hoursAgo: 30,
            likeCount: 183,
            index: 4
        ))

        result.append(makePost(
            authorId: deterministicUUID(for: "abiding-faith-church"),
            authorName: "Abiding Faith Church",
            authorType: "church",
            content: "\"Trust in the LORD with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.\" — Proverbs 3:5-6\n\nHave a blessed week! 🙏",
            photoUrl: nil,
            videoUrl: nil,
            postType: "update",
            hoursAgo: 44,
            likeCount: 76,
            index: 5
        ))

        result.append(makePost(
            authorId: deterministicUUID(for: "unity-methodist-church"),
            authorName: "Unity Methodist Church",
            authorType: "church",
            content: "Wednesday Bible Study tonight at 7 PM. We are continuing our study of Romans. Come with your questions — there are no bad ones. ☕📖",
            photoUrl: nil,
            videoUrl: nil,
            postType: "update",
            hoursAgo: 52,
            likeCount: 49,
            index: 6
        ))

        result.append(makePost(
            authorId: deterministicUUID(for: "hillsong-church-los-angeles"),
            authorName: "Hillsong Church Los Angeles",
            authorType: "church",
            content: "Watch last Sunday's full sermon replay — \"You Are Not Alone\". One of the most powerful messages we have shared this year. Link below. 💙",
            photoUrl: nil,
            videoUrl: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            postType: "update",
            hoursAgo: 72,
            likeCount: 318,
            index: 7
        ))

        return result
    }

    // MARK: - Church events

    /// Returns realistic upcoming events for the given church.
    static func events(forChurch churchName: String) -> [Event] {
        guard enabled else { return [] }

        let authorId = deterministicUUID(for: churchName)

        let templates: [(title: String, description: String, daysFromNow: Int, location: String)] = [
            (
                "Sunday Worship Service",
                "Join us for an uplifting Sunday morning worship experience. All are welcome.",
                3,
                "\(churchName) — Main Sanctuary"
            ),
            (
                "Wednesday Bible Study",
                "An in-depth study of Scripture with time for questions and discussion.",
                6,
                "\(churchName) — Fellowship Hall"
            ),
            (
                "Youth Night",
                "A high-energy evening of worship, games, and community for teens and young adults.",
                9,
                "\(churchName) — Youth Center"
            ),
            (
                "Prayer & Worship Gathering",
                "A quiet evening set apart for corporate prayer and intimate worship.",
                13,
                "\(churchName) — Chapel"
            ),
            (
                "Community Outreach Saturday",
                "We're serving our neighborhood together. Bring gloves and a servant's heart.",
                16,
                "Meet at the church parking lot"
            ),
            (
                "Easter Sunday Celebration",
                "He is risen! Join us for a special Easter Sunday service with live worship, drama, and a message of hope.",
                20,
                "\(churchName) — Main Sanctuary"
            )
        ]

        return templates.enumerated().map { i, t in
            makeEvent(
                authorId: authorId,
                authorName: churchName,
                title: t.title,
                description: t.description,
                daysFromNow: t.daysFromNow,
                location: t.location,
                index: i
            )
        }
    }

    // MARK: - Feed events strip

    static var feedEvents: [Event] {
        guard enabled else { return [] }
        return [
            makeEvent(
                authorName: "Grace Community Church",
                title: "Sunday Worship Service",
                description: "All are welcome.",
                daysFromNow: 3,
                location: "Atlanta, GA"
            ),
            makeEvent(
                authorName: "Hillsong Church Los Angeles",
                title: "Youth Night",
                description: nil,
                daysFromNow: 5,
                location: "Los Angeles, CA"
            ),
            makeEvent(
                authorName: "Unity Methodist Church",
                title: "Prayer & Worship Gathering",
                description: nil,
                daysFromNow: 8,
                location: "Chapel"
            ),
            makeEvent(
                authorName: "West Angeles COGIC",
                title: "Community Outreach",
                description: "Serving our neighborhood together.",
                daysFromNow: 11,
                location: "Los Angeles, CA"
            )
        ]
    }

    // MARK: - Live churches for feed banner

    static var liveFeedChurches: [ChurchSubmission] {
        guard enabled else { return [] }
        return [
            makeChurchSubmission(name: "Grace Community Church"),
            makeChurchSubmission(name: "Hillsong Church Los Angeles")
        ]
    }

    // MARK: - Follower count seeds

    // MARK: - People discovery

    static var suggestedUsers: [DiscoverableUser] {
        guard enabled else { return [] }
        return allSeedUsers
    }

    // MARK: - Church leadership

    /// Returns a realistic lead pastor for the given church.
    static func leaders(forChurch churchName: String) -> [Leader] {
        guard enabled else { return [] }

        let pool: [(name: String, title: String, bio: String)] = [
            (
                "Pastor David Thompson",
                "Lead Pastor",
                "Pastor David has served in ministry for over 20 years, planting churches across the Southeast. He is passionate about expository preaching, discipleship, and building communities rooted in grace. He and his wife, Sarah, have three children."
            ),
            (
                "Pastor James & Maria Rivera",
                "Senior Pastors",
                "Pastor James and First Lady Maria have led their congregation with a heart for the community and a commitment to biblical truth. Together they oversee worship, outreach, and small group ministry."
            ),
            (
                "Bishop Calvin Okafor",
                "Bishop & Founder",
                "Bishop Okafor founded the church in 1998 with a vision to see lives transformed by the Gospel. Known for his powerful preaching and compassionate leadership, he has mentored hundreds of ministers across the country."
            ),
            (
                "Pastor Michelle Grant",
                "Senior Pastor",
                "Pastor Michelle brings over 15 years of pastoral experience to her role. She is a gifted communicator and author whose messages on faith, identity, and purpose have reached audiences around the world."
            ),
            (
                "Rev. Thomas & Angela Brooks",
                "Lead Pastors",
                "Rev. Thomas and Angela have served this congregation for 12 years, building a church known for its warmth, creativity, and commitment to the next generation. Their ministry is grounded in the belief that every person has a God-given destiny."
            )
        ]

        let index = abs(churchName.hashValue) % pool.count
        let p = pool[index]

        return [
            Leader(
                id: deterministicUUID(for: "leader-\(churchName)"),
                name: p.name,
                title: p.title,
                bio: p.bio,
                photoUrl: nil
            )
        ]
    }

    // MARK: - Notifications

    static var notifications: [AppNotification] {
        guard enabled else { return [] }
        let userId    = deterministicUUID(for: "demo-user")
        // Actor user IDs — must match _uid(n) in MockSeedData
        let marcus    = deterministicUUID(for: "seed-user-0")   // Marcus Williams
        let james     = deterministicUUID(for: "seed-user-2")   // James Torres
        let angela    = deterministicUUID(for: "seed-user-3")   // Angela Brooks

        return [
            makeNotification(
                userId: userId, type: "church_live",
                title: "Grace Community Church is LIVE",
                body: "Sunday Morning Worship has started. Tap to watch now.",
                minutesAgo: 12, isRead: false,
                churchSlug: "grace-community-church"
            ),
            makeNotification(
                userId: userId, type: "new_follower",
                title: "Marcus Williams followed you",
                body: "Pastor · Atlanta, GA · Baptist",
                minutesAgo: 28, isRead: false,
                actorUserId: marcus
            ),
            makeNotification(
                userId: userId, type: "new_event",
                title: "New Event: Youth Night",
                body: "Unity Methodist Church added Youth Night on Friday at 6:30 PM.",
                minutesAgo: 45, isRead: false,
                churchSlug: "unity-methodist-church"
            ),
            makeNotification(
                userId: userId, type: "new_follower",
                title: "Angela Brooks followed you",
                body: "Worship leader · Charlotte, NC · Methodist",
                minutesAgo: 90, isRead: false,
                actorUserId: angela
            ),
            makeNotification(
                userId: userId, type: "new_post",
                title: "Hillsong LA posted an update",
                body: "\"Join us this Sunday as we wrap up our series 'Good Good Father'…\"",
                minutesAgo: 180, isRead: true,
                churchSlug: "hillsong-church-los-angeles",
                postId: deterministicUUID(for: "Hillsong Church Los Angeles-post-2")
            ),
            makeNotification(
                userId: userId, type: "new_event",
                title: "New Event: Easter Sunday Celebration",
                body: "Grace Community Church is hosting a special Easter service on April 20.",
                minutesAgo: 360, isRead: true,
                churchSlug: "grace-community-church",
                eventId: deterministicUUID(for: "Grace Community Church-event-5")
            ),
            makeNotification(
                userId: userId, type: "church_live",
                title: "West Angeles COGIC is LIVE",
                body: "Wednesday Mid-Week Service is streaming right now.",
                minutesAgo: 1440, isRead: true,
                churchSlug: "west-angeles-church-of-god-in-christ"
            ),
            makeNotification(
                userId: userId, type: "new_post",
                title: "Unity Methodist Church posted",
                body: "\"Wednesday Bible Study is tonight at 7 PM. We're going through Romans…\"",
                minutesAgo: 2880, isRead: true,
                churchSlug: "unity-methodist-church",
                postId: deterministicUUID(for: "Unity Methodist Church-post-6")
            ),
            makeNotification(
                userId: userId, type: "new_follower",
                title: "James Torres followed you",
                body: "Worship leader · Los Angeles, CA · Pentecostal",
                minutesAgo: 4320, isRead: true,
                actorUserId: james
            )
        ]
    }

    private static func makeNotification(
        userId: UUID,
        type: String,
        title: String,
        body: String?,
        minutesAgo: Int,
        isRead: Bool,
        relatedId: UUID? = nil,
        actorUserId: UUID? = nil,
        churchSlug: String? = nil,
        postId: UUID? = nil,
        eventId: UUID? = nil
    ) -> AppNotification {
        AppNotification(
            id: deterministicUUID(for: "\(type)-\(title)-\(minutesAgo)"),
            userId: userId,
            type: type,
            title: title,
            body: body,
            relatedId: relatedId,
            actorUserId: actorUserId,
            churchSlug: churchSlug,
            postId: postId,
            eventId: eventId,
            isRead: isRead,
            createdAt: Date().addingTimeInterval(TimeInterval(-minutesAgo * 60))
        )
    }

    /// Returns a seeded (non-zero) follower count for a church in demo mode.
    static func followerCount(forSlug slug: String) -> Int {
        guard enabled else { return 0 }
        let base = abs(slug.hashValue) % 800
        return base + 120  // range: 120 – 919
    }

    // MARK: - Private helpers

    private static func makePost(
        authorId: UUID,
        authorName: String,
        authorType: String,
        content: String?,
        photoUrl: String?,
        videoUrl: String?,
        postType: String,
        hoursAgo: Int,
        likeCount: Int,
        index: Int
    ) -> Post {
        Post(
            id: deterministicUUID(for: "\(authorName)-post-\(index)"),
            authorId: authorId,
            authorName: authorName,
            authorType: authorType,
            content: content,
            photoUrl: photoUrl,
            videoUrl: videoUrl,
            postType: postType,
            likeCount: likeCount,
            createdAt: Date().addingTimeInterval(TimeInterval(-hoursAgo * 3600)),
            isLiked: false
        )
    }

    private static func makeEvent(
        authorId: UUID = UUID(),
        authorName: String,
        title: String,
        description: String?,
        daysFromNow: Int,
        location: String,
        index: Int = 0
    ) -> Event {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day = (components.day ?? 0) + daysFromNow
        components.hour = 10
        components.minute = 0
        let eventDate = calendar.date(from: components) ?? Date()

        return Event(
            id: deterministicUUID(for: "\(authorName)-event-\(index)"),
            authorId: authorId,
            authorName: authorName,
            title: title,
            description: description,
            eventDate: eventDate,
            location: location,
            createdAt: Date().addingTimeInterval(-86400)
        )
    }

    private static func makeChurchSubmission(name: String) -> ChurchSubmission {
        ChurchSubmission(
            id: deterministicUUID(for: "submission-\(name)"),
            userId: deterministicUUID(for: "user-\(name)"),
            churchName: name,
            isLive: true,
            status: "approved",
            denomination: nil,
            phone: nil,
            website: nil,
            serviceTimes: nil,
            about: nil
        )
    }

    /// Produces the same UUID for the same string every time — no randomness.
    static func deterministicUUID(for key: String) -> UUID {
        var hash = key.utf8.reduce(UInt64(0x811c9dc5)) { acc, byte in
            (acc ^ UInt64(byte)) &* 0x01000193
        }
        // Fill 16 bytes from the 64-bit hash
        var bytes = [UInt8](repeating: 0, count: 16)
        for i in 0..<8 {
            bytes[i]     = UInt8(hash & 0xFF); hash >>= 8
        }
        hash = key.utf8.reduce(UInt64(0xcbf29ce484222325)) { acc, byte in
            (acc ^ UInt64(byte)) &* 0x100000001b3
        }
        for i in 8..<16 {
            bytes[i] = UInt8(hash & 0xFF); hash >>= 8
        }
        // Set UUID version 4 bits
        bytes[6] = (bytes[6] & 0x0F) | 0x40
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0],  bytes[1],  bytes[2],  bytes[3],
            bytes[4],  bytes[5],  bytes[6],  bytes[7],
            bytes[8],  bytes[9],  bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}
