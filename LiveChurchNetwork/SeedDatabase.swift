import Foundation
import Supabase

/// Cleans and seeds the database with test data
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
        // Delete in order of foreign key dependencies
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

        for (index, name) in churchNames.enumerated() {
            let userId = UUID()
            let churchId = UUID()

            // Create profile for church admin
            try await client.from("profiles").insert([
                "id": userId.uuidString,
                "full_name": name,
                "role": "church_admin",
                "bio": "Welcoming church in the community",
                "city": ["Austin", "Dallas", "Houston", "San Antonio", "New Braunfels"][index % 5],
                "denomination": denominations[index % 10]
            ]).execute()

            // Create church submission
            try await client.from("church_submissions").insert([
                "id": churchId.uuidString,
                "user_id": userId.uuidString,
                "church_name": name,
                "denomination": denominations[index % 10],
                "phone": "512-555-\(String(format: "%04d", 1000 + index))",
                "website": "https://\(name.lowercased().replacingOccurrences(of: " ", with: "")).com",
                "service_times": "Sundays 9am, 11am",
                "about": "We are a loving community dedicated to serving God and each other.",
                "is_live": index % 3 == 0,
                "status": "approved"
            ]).execute()

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

            try await client.from("profiles").insert([
                "id": userId.uuidString,
                "full_name": name,
                "role": "worshipper",
                "bio": "Just a regular person exploring faith and community",
                "city": cities[index],
                "denomination": denominations[index]
            ]).execute()

            worshippers.append(WorshipperData(userId: userId, name: name, city: cities[index]))
            print("  ✓ Created worshipper: \(name)")
        }

        return worshippers
    }

    private func setupFollows(churches: [ChurchData], worshippers: [WorshipperData]) async throws {
        // Each worshipper follows 3-5 random churches
        for worshipper in worshippers {
            let numFollows = Int.random(in: 3...5)
            let shuffledChurches = churches.shuffled()

            for i in 0..<numFollows {
                let church = shuffledChurches[i]
                try await client.from("follows").insert([
                    "follower_id": worshipper.userId.uuidString,
                    "following_id": church.userId.uuidString,
                    "following_type": "worshipper"
                ]).execute()
            }
        }

        // Each worshipper also follows 2-3 other worshippers
        for worshipper in worshippers {
            let numFollows = Int.random(in: 2...3)
            let others = worshippers.filter { $0.userId != worshipper.userId }.shuffled()

            for i in 0..<min(numFollows, others.count) {
                try await client.from("follows").insert([
                    "follower_id": worshipper.userId.uuidString,
                    "following_id": others[i].userId.uuidString,
                    "following_type": "worshipper"
                ]).execute()
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

        // Churches create 2-3 posts each
        for church in churches {
            let numPosts = Int.random(in: 2...3)
            for _ in 0..<numPosts {
                let postType = postTypes.randomElement() ?? "update"
                let content = contents.randomElement() ?? "Hello community!"

                try await client.from("posts").insert([
                    "id": UUID().uuidString,
                    "author_id": church.userId.uuidString,
                    "author_name": church.name,
                    "author_type": "church",
                    "content": content,
                    "post_type": postType,
                    "is_important": Bool.random(),
                    "is_pinned": false,
                    "like_count": 0,
                    "created_at": ISO8601DateFormatter().string(from: Date())
                ]).execute()
            }
        }

        // Worshippers create 1-2 posts each
        for worshipper in worshippers {
            let numPosts = Int.random(in: 1...2)
            for _ in 0..<numPosts {
                let postType = ["prayer", "update"].randomElement() ?? "update"
                let content = contents.randomElement() ?? "Hello church family!"

                try await client.from("posts").insert([
                    "id": UUID().uuidString,
                    "author_id": worshipper.userId.uuidString,
                    "author_name": worshipper.name,
                    "author_type": "worshipper",
                    "content": content,
                    "post_type": postType,
                    "is_important": false,
                    "is_pinned": false,
                    "like_count": 0,
                    "created_at": ISO8601DateFormatter().string(from: Date())
                ]).execute()
            }
        }

        print("  ✓ Sample posts created")
    }
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
