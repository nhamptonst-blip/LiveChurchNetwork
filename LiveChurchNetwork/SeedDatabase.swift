import Foundation
import Supabase

class DatabaseSeeder {
    let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func cleanAndSeed() async throws {
        print("🧹 Cleaning database...")
        try await cleanDatabase()

        print("🌱 Seeding test data...")
        let churches = try await createChurches()
        let worshippers = try await createWorshippers()

        print("🔗 Setting up follows...")
        try await setupFollows(churches: churches, worshippers: worshippers)

        print("📝 Creating sample posts...")
        try await createSamplePosts(churches: churches, worshippers: worshippers)

        print("✅ Database seeding complete!")
    }

    private func cleanDatabase() async throws {
        try await client.from("comments").delete().execute()
        try await client.from("likes").delete().execute()
        try await client.from("notifications").delete().execute()
        try await client.from("follows").delete().execute()
        try await client.from("saved_churches").delete().execute()
        try await client.from("church_inquiries").delete().execute()
        try await client.from("posts").delete().execute()
        try await client.from("events").delete().execute()
        try await client.from("church_submissions").delete().execute()
        try await client.from("profiles").delete().execute()
        print("  ✓ Database cleaned")
    }

    private func createChurches() async throws -> [ChurchData] {
        var churches: [ChurchData] = []

        let churchNames = [
            "Grace Community Church",
            "Cornerstone Fellowship",
            "Living Hope Baptist",
            "Bethel Assembly",
            "Trinity Church",
            "Shepherd's Fold",
            "New Life Christian",
            "Harvest Church",
            "Covenant Assembly",
            "Restoration Church"
        ]

        let denominations = ["Baptist", "Pentecostal", "Methodist", "Lutheran", "Presbyterian", "Evangelical", "Assembly of God", "Bible Church", "Christian", "Reformed"]
        let cities = ["Austin", "Dallas", "Houston", "San Antonio", "New Braunfels"]

        for (index, name) in churchNames.enumerated() {
            let userId = UUID()
            let churchId = UUID()

            try await client.from("profiles").insert(ProfileInsert(
                id: userId.uuidString,
                full_name: name,
                role: "church_admin",
                bio: "Welcoming church in the community",
                city: cities[index % 5],
                denomination: denominations[index % 10]
            )).execute()

            try await client.from("church_submissions").insert(ChurchSubmissionInsert(
                id: churchId.uuidString,
                user_id: userId.uuidString,
                church_name: name,
                denomination: denominations[index % 10],
                phone: "512-555-\(String(format: "%04d", 1000 + index))",
                website: "https://\(name.lowercased().replacingOccurrences(of: " ", with: "")).com",
                service_times: "Sundays 9am, 11am",
                about: "We are a loving community dedicated to serving God and each other.",
                is_live: index % 3 == 0,
                status: "approved"
            )).execute()

            churches.append(ChurchData(userId: userId, churchId: churchId, name: name))
            print("  ✓ Created church: \(name)")
        }

        return churches
    }

    private func createWorshippers() async throws -> [WorshipperData] {
        var worshippers: [WorshipperData] = []

        let firstNames = ["John", "Sarah", "Michael", "Emily", "David", "Jessica", "Daniel", "Amanda", "James", "Jennifer"]
        let lastNames = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez"]
        let cities = ["Austin", "Dallas", "Houston", "San Antonio", "New Braunfels", "Dripping Springs", "Cedar Park", "Pflugerville", "Round Rock", "Leander"]
        let denominations = ["Baptist", "Pentecostal", "Methodist", "Lutheran", "Presbyterian", "", "", "", "", ""]

        for index in 0..<10 {
            let userId = UUID()
            let name = "\(firstNames[index]) \(lastNames[index])"

            try await client.from("profiles").insert(ProfileInsert(
                id: userId.uuidString,
                full_name: name,
                role: "worshipper",
                bio: "Just a regular person exploring faith and community",
                city: cities[index],
                denomination: denominations[index]
            )).execute()

            worshippers.append(WorshipperData(userId: userId, name: name, city: cities[index]))
            print("  ✓ Created worshipper: \(name)")
        }

        return worshippers
    }

    private func setupFollows(churches: [ChurchData], worshippers: [WorshipperData]) async throws {
        for worshipper in worshippers {
            let numFollows = Int.random(in: 3...5)
            let shuffledChurches = churches.shuffled()

            for i in 0..<numFollows {
                let church = shuffledChurches[i]
                try await client.from("follows").insert(FollowInsert(
                    follower_id: worshipper.userId.uuidString,
                    following_id: church.userId.uuidString,
                    following_type: "church"
                )).execute()
            }
        }

        for worshipper in worshippers {
            let numFollows = Int.random(in: 2...3)
            let others = worshippers.filter { $0.userId != worshipper.userId }.shuffled()

            for i in 0..<min(numFollows, others.count) {
                try await client.from("follows").insert(FollowInsert(
                    follower_id: worshipper.userId.uuidString,
                    following_id: others[i].userId.uuidString,
                    following_type: "worshipper"
                )).execute()
            }
        }

        print("  ✓ Follows configured")
    }

    private func createSamplePosts(churches: [ChurchData], worshippers: [WorshipperData]) async throws {
        let postTypes = ["announcement", "verse", "prayer", "update", "event"]
        let contents = [
            "Join us for our Sunday service this week!",
            "Jesus said, 'Peace I leave with you; my peace I give you.'",
            "Praying for all those affected by recent storms. Our hearts are with you.",
            "Great turnout at our community service day yesterday!",
            "Don't miss our special worship night this Friday at 7pm",
            "Thank you to all the volunteers who helped at our food bank today",
            "Our youth group is going on a mission trip next month",
            "Blessed to serve in this wonderful community",
            "Remember: God is always faithful",
            "Community event this Saturday - everyone welcome!"
        ]

        for church in churches {
            let numPosts = Int.random(in: 2...3)
            for _ in 0..<numPosts {
                let postType = postTypes.randomElement() ?? "update"
                let content = contents.randomElement() ?? "Hello community!"

                try await client.from("posts").insert(PostInsert(
                    author_id: church.userId.uuidString,
                    author_name: church.name,
                    author_type: "church",
                    content: content,
                    photo_url: nil,
                    video_url: nil,
                    post_type: postType,
                    is_important: Bool.random(),
                    is_pinned: false,
                    send_notification: false,
                    highlight_in_feed: false
                )).execute()
            }
        }

        for worshipper in worshippers {
            let numPosts = Int.random(in: 1...2)
            for _ in 0..<numPosts {
                let postType = ["prayer", "update"].randomElement() ?? "update"
                let content = contents.randomElement() ?? "Hello church family!"

                try await client.from("posts").insert(PostInsert(
                    author_id: worshipper.userId.uuidString,
                    author_name: worshipper.name,
                    author_type: "worshipper",
                    content: content,
                    photo_url: nil,
                    video_url: nil,
                    post_type: postType,
                    is_important: false,
                    is_pinned: false,
                    send_notification: false,
                    highlight_in_feed: false
                )).execute()
            }
        }

        print("  ✓ Sample posts created")
    }
}

// MARK: - Insert payload structs

private struct ProfileInsert: Encodable {
    let id: String
    let full_name: String
    let role: String
    let bio: String
    let city: String
    let denomination: String
}

private struct ChurchSubmissionInsert: Encodable {
    let id: String
    let user_id: String
    let church_name: String
    let denomination: String
    let phone: String
    let website: String
    let service_times: String
    let about: String
    let is_live: Bool
    let status: String
}

private struct FollowInsert: Encodable {
    let follower_id: String
    let following_id: String
    let following_type: String
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

struct ChurchData {
    let userId: UUID
    let churchId: UUID
    let name: String
}

struct WorshipperData {
    let userId: UUID
    let name: String
    let city: String
}
