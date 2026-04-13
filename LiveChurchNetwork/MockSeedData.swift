import Foundation

// MARK: - Seed Data
// 30 realistic test accounts with posts, social graph, and church follows.
// Referenced by MockDataProvider — disable by setting MockDataProvider.enabled = false.

extension MockDataProvider {

    static var allSeedUsers: [DiscoverableUser] {
        guard enabled else { return [] }
        return _seedUsers
    }

    static func posts(forUser userId: UUID) -> [Post] {
        guard enabled else { return [] }
        return _userPosts[userId] ?? []
    }

    static var userFeedPosts: [Post] {
        guard enabled else { return [] }
        return _userPosts.values
            .flatMap { $0.prefix(2) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    static var followGraph: [UUID: [UUID]] { _followGraph }
    static var churchFollowGraph: [UUID: [String]] { _churchFollowGraph }
}

// MARK: - User definitions

private let _seedUsers: [DiscoverableUser] = _userData

private let _userData: [DiscoverableUser] = [
    DiscoverableUser(id: _uid(0),  name: "Marcus Williams",
        bio: "Pastor, husband, father of three. Twenty years in ministry and still learning. Passionate about community, expository preaching, and mentoring the next generation.",
        denomination: "Baptist", city: "Atlanta, GA",
        photoUrl: "https://i.pravatar.cc/300?img=33",
        coverImageUrl: "https://source.unsplash.com/800x300/?church,sermon,worship&sig=101",
        followerCount: 847,  followingCount: 38,
        churchSlugs: ["grace-community-church", "eagle-rock-baptist-church", "abiding-faith-church"]),
    DiscoverableUser(id: _uid(1),  name: "Priya Okafor",
        bio: "Grateful for grace every single day. Finance analyst by week, worship volunteer on weekends. First-gen believer.",
        denomination: "Non-Denominational", city: "Houston, TX",
        photoUrl: "https://i.pravatar.cc/300?img=5",
        coverImageUrl: "https://source.unsplash.com/800x300/?worship,contemporary,church&sig=102",
        followerCount: 312,  followingCount: 117,
        churchSlugs: ["hillsong-church-los-angeles", "oasis-church-la", "thrive-la-church"]),
    DiscoverableUser(id: _uid(2),  name: "James Torres",
        bio: "Worship leader, church planter in training. Married to Rachel. We love the local church and believe in the power of a room full of people singing together.",
        denomination: "Pentecostal", city: "Los Angeles, CA",
        photoUrl: "https://i.pravatar.cc/300?img=8",
        coverImageUrl: "https://source.unsplash.com/800x300/?worship,praise,singing&sig=103",
        followerCount: 1240, followingCount: 55,
        churchSlugs: ["angelus-temple-dream-center", "angelus-temple-foursquare-church-pentecostal", "west-angeles-church-of-god-in-christ"]),
    DiscoverableUser(id: _uid(3),  name: "Angela Brooks",
        bio: "Worship leader and music teacher. Coffee and Psalms every morning. Methodist by tradition, charismatic by experience.",
        denomination: "Methodist", city: "Charlotte, NC",
        photoUrl: "https://i.pravatar.cc/300?img=1",
        coverImageUrl: "https://source.unsplash.com/800x300/?gospel,choir,music&sig=104",
        followerCount: 589,  followingCount: 44,
        churchSlugs: ["crenshaw-united-methodist-church", "unity-methodist-church", "holman-united-methodist-church", "hollywood-united-methodist-church"]),
    DiscoverableUser(id: _uid(4),  name: "David Osei",
        bio: "M.Div. student. Deep in Romans right now and it's wrecking me in the best way. Reformed theology, warm heart.",
        denomination: "Presbyterian", city: "Dallas, TX",
        photoUrl: "https://i.pravatar.cc/300?img=12",
        coverImageUrl: "https://source.unsplash.com/800x300/?bible,scripture,faith&sig=105",
        followerCount: 203,  followingCount: 19,
        churchSlugs: ["bel-air-presbyterian-church", "first-presbyterian-church-of-hollywood", "westminster-presbyterian-church"]),
    DiscoverableUser(id: _uid(5),  name: "Lisa Fernandez",
        bio: "Catholic mom of three. I show up every Sunday even when it's hard. Prayer warrior, terrible cook, excellent hugger.",
        denomination: "Catholic", city: "Miami, FL",
        photoUrl: "https://i.pravatar.cc/300?img=16",
        coverImageUrl: "https://source.unsplash.com/800x300/?cathedral,chapel,candles&sig=106",
        followerCount: 156,  followingCount: 22,
        churchSlugs: ["cathedral-of-our-lady-of-the-angels", "st-vincent-de-paul-catholic-church", "st-brendan-catholic-church"]),
    DiscoverableUser(id: _uid(6),  name: "Samuel Adeyemi",
        bio: "Evangelist at heart. Content creator. If this platform has a feed, I'm filling it with the Gospel. Nigerian-American. Chicago made.",
        denomination: "Non-Denominational", city: "Chicago, IL",
        photoUrl: "https://i.pravatar.cc/300?img=19",
        coverImageUrl: "https://source.unsplash.com/800x300/?preaching,gospel,outreach&sig=107",
        followerCount: 2100, followingCount: 203,
        churchSlugs: ["new-city-church-la", "fearless-la-church", "core-church-la", "oasis-church"]),
    DiscoverableUser(id: _uid(7),  name: "Tanya Mitchell",
        bio: "Singer-songwriter. Baptist church raised me, gospel music kept me. Sessions musician by day, worship leader whenever the Spirit moves.",
        denomination: "Baptist", city: "Nashville, TN",
        photoUrl: "https://i.pravatar.cc/300?img=22",
        coverImageUrl: "https://source.unsplash.com/800x300/?worship,music,praise&sig=108",
        followerCount: 1890, followingCount: 62,
        churchSlugs: ["west-angeles-church-of-god-in-christ", "crenshaw-christian-center-faithdome", "first-african-methodist-episcopal-church", "grace-community-church"]),
    DiscoverableUser(id: _uid(8),  name: "Robert Washington",
        bio: "Deacon at First AME. Third-generation churchman. Believe deeply in the Black church tradition as a cornerstone of community and justice.",
        denomination: "AME", city: "Philadelphia, PA",
        photoUrl: "https://i.pravatar.cc/300?img=25",
        coverImageUrl: "https://source.unsplash.com/800x300/?black,church,community&sig=109",
        followerCount: 445,  followingCount: 31,
        churchSlugs: ["first-african-methodist-episcopal-church", "first-african-methodist-episcopal-church-of-los-angeles-fame", "west-angeles-church-of-god-in-christ"]),
    DiscoverableUser(id: _uid(9),  name: "Grace Kim",
        bio: "Graphic designer. Made in Korea, grown in Seattle. My faith and my art are the same thing to me.",
        denomination: "Non-Denominational", city: "Seattle, WA",
        photoUrl: "https://i.pravatar.cc/300?img=29",
        coverImageUrl: "https://source.unsplash.com/800x300/?sunrise,prayer,reflection&sig=110",
        followerCount: 278,  followingCount: 89,
        churchSlugs: ["union-church-of-los-angeles", "tapestry-la-church", "silverlake-community-church"]),
    DiscoverableUser(id: _uid(10), name: "Emmanuel Asante",
        bio: "High school teacher. Raised in Ghana, rooted in Minneapolis. Serving my church community one Tuesday night at a time.",
        denomination: "Baptist", city: "Minneapolis, MN",
        photoUrl: "https://i.pravatar.cc/300?img=32",
        coverImageUrl: "https://source.unsplash.com/800x300/?church,fellowship,faith&sig=111",
        followerCount: 167,  followingCount: 26,
        churchSlugs: ["grace-community-church", "eagle-rock-baptist-church", "abiding-faith-church"]),
    DiscoverableUser(id: _uid(11), name: "Keisha Thompson",
        bio: "NICU nurse. Catholic. I've seen too many miracles to be cynical. Every shift is an act of worship.",
        denomination: "Catholic", city: "New Orleans, LA",
        photoUrl: "https://i.pravatar.cc/300?img=35",
        coverImageUrl: "https://source.unsplash.com/800x300/?cathedral,prayer,candles&sig=112",
        followerCount: 89,   followingCount: 14,
        churchSlugs: ["cathedral-of-our-lady-of-the-angels", "our-mother-of-good-counsel-catholic-church", "st-mary-of-the-angels-church-hollywood"]),
    DiscoverableUser(id: _uid(12), name: "Nathan Pierce",
        bio: "Youth pastor at a small Lutheran church in Denver. We have 40 kids who think church is boring but keep showing up — and that tells me everything.",
        denomination: "Lutheran", city: "Denver, CO",
        photoUrl: "https://i.pravatar.cc/300?img=38",
        coverImageUrl: "https://source.unsplash.com/800x300/?youth,church,community&sig=113",
        followerCount: 634,  followingCount: 47,
        churchSlugs: ["bel-air-presbyterian-church", "first-presbyterian-church-of-hollywood", "grace-community-church"]),
    DiscoverableUser(id: _uid(13), name: "Destiny Owens",
        bio: "Entrepreneur. Pentecostal fire still burning since age 16. I believe God is in the building and in the boardroom.",
        denomination: "Pentecostal", city: "Detroit, MI",
        photoUrl: "https://i.pravatar.cc/300?img=41",
        coverImageUrl: "https://source.unsplash.com/800x300/?worship,fire,prayer&sig=114",
        followerCount: 721,  followingCount: 78,
        churchSlugs: ["west-angeles-church-of-god-in-christ", "angelus-temple-dream-center", "crenshaw-christian-center-faithdome"]),
    DiscoverableUser(id: _uid(14), name: "Carlos Reyes",
        bio: "Construction foreman. Catholic. God is good on the job site and at the altar. Familia primero.",
        denomination: "Catholic", city: "San Antonio, TX",
        photoUrl: "https://i.pravatar.cc/300?img=44",
        coverImageUrl: "https://source.unsplash.com/800x300/?mission,cross,chapel&sig=115",
        followerCount: 94,   followingCount: 11,
        churchSlugs: ["cathedral-of-our-lady-of-the-angels", "st-vincent-de-paul-catholic-church", "our-mother-of-good-counsel-catholic-church"]),
    DiscoverableUser(id: _uid(15), name: "Abigail Johnson",
        bio: "Senior at Spelman. Theology major, campus ministry leader. The church got me through everything — now I want to give it back.",
        denomination: "Baptist", city: "Atlanta, GA",
        photoUrl: "https://i.pravatar.cc/300?img=47",
        coverImageUrl: "https://source.unsplash.com/800x300/?church,college,faith&sig=116",
        followerCount: 445,  followingCount: 134,
        churchSlugs: ["grace-community-church", "abiding-faith-church", "new-city-church-la"]),
    DiscoverableUser(id: _uid(16), name: "Joshua Bennett",
        bio: "Software engineer by day. Studying Acts on the side. Non-denom. I love the church even when it's messy.",
        denomination: "Non-Denominational", city: "Portland, OR",
        photoUrl: "https://i.pravatar.cc/300?img=50",
        coverImageUrl: "https://source.unsplash.com/800x300/?sunrise,peace,morning&sig=117",
        followerCount: 332,  followingCount: 56,
        churchSlugs: ["oasis-church", "core-church-la", "union-church-of-los-angeles"]),
    DiscoverableUser(id: _uid(17), name: "Patricia Nwosu",
        bio: "Nonprofit director. Nigerian-American. I believe the church should be the most practical place in any city. That's what I'm building toward.",
        denomination: "Non-Denominational", city: "Silver Spring, MD",
        photoUrl: "https://i.pravatar.cc/300?img=53",
        coverImageUrl: "https://source.unsplash.com/800x300/?community,service,volunteers&sig=118",
        followerCount: 567,  followingCount: 49,
        churchSlugs: ["new-city-church-la", "fearless-la-church", "mercy-town"]),
    DiscoverableUser(id: _uid(18), name: "Michael Torres",
        bio: "Retired Army chaplain. Episcopal. Forty years of service taught me that God is present in the hardest places. Now I teach that to others.",
        denomination: "Episcopal", city: "Phoenix, AZ",
        photoUrl: "https://i.pravatar.cc/300?img=56",
        coverImageUrl: "https://source.unsplash.com/800x300/?desert,sunrise,cross&sig=119",
        followerCount: 234,  followingCount: 17,
        churchSlugs: ["st-james-episcopal-church-in-the-city-mid-wilshire", "church-of-the-epiphany-iglesia-de-la-epifania"]),
    DiscoverableUser(id: _uid(19), name: "Blessing Adebayo",
        bio: "Social worker. Methodist. God's grace is most visible in the margins — and that's where I try to work.",
        denomination: "Methodist", city: "Columbus, OH",
        photoUrl: "https://i.pravatar.cc/300?img=59",
        coverImageUrl: "https://source.unsplash.com/800x300/?grace,mercy,church&sig=120",
        followerCount: 189,  followingCount: 34,
        churchSlugs: ["unity-methodist-church", "crenshaw-united-methodist-church", "la-plaza-united-methodist-church"]),
    DiscoverableUser(id: _uid(20), name: "Sarah Chen",
        bio: "Visual artist. Brooklyn-based. My faith is the lens through which I see everything. I paint, I worship, I wonder.",
        denomination: "Non-Denominational", city: "Brooklyn, NY",
        photoUrl: "https://i.pravatar.cc/300?img=62",
        coverImageUrl: "https://source.unsplash.com/800x300/?worship,art,light&sig=121",
        followerCount: 1100, followingCount: 91,
        churchSlugs: ["hillsong-church-los-angeles", "tapestry-la-church", "silverlake-community-church"]),
    DiscoverableUser(id: _uid(21), name: "Daniel Okonkwo",
        bio: "Associate pastor. Preaching and discipleship. I believe the Sunday sermon is just the beginning of a longer conversation.",
        denomination: "Baptist", city: "Richmond, VA",
        photoUrl: "https://i.pravatar.cc/300?img=65",
        coverImageUrl: "https://source.unsplash.com/800x300/?preaching,sunday,church&sig=122",
        followerCount: 892,  followingCount: 43,
        churchSlugs: ["grace-community-church", "eagle-rock-baptist-church", "abiding-faith-church"]),
    DiscoverableUser(id: _uid(22), name: "Hope Martinez",
        bio: "Elementary teacher. Catholic. I named my daughter Faith, my son Emmanuel. That tells you everything about me.",
        denomination: "Catholic", city: "Albuquerque, NM",
        photoUrl: "https://i.pravatar.cc/300?img=68",
        coverImageUrl: "https://source.unsplash.com/800x300/?church,family,faith&sig=123",
        followerCount: 145,  followingCount: 18,
        churchSlugs: ["cathedral-of-our-lady-of-the-angels", "our-mother-of-good-counsel-catholic-church"]),
    DiscoverableUser(id: _uid(23), name: "Elijah Freeman",
        bio: "Musician, producer, worshipper. Baltimore. I believe music is one of the most powerful forms of prayer we have.",
        denomination: "Non-Denominational", city: "Baltimore, MD",
        photoUrl: "https://i.pravatar.cc/300?img=9",
        coverImageUrl: "https://source.unsplash.com/800x300/?worship,music,guitar&sig=124",
        followerCount: 678,  followingCount: 88,
        churchSlugs: ["west-angeles-church-of-god-in-christ", "crenshaw-christian-center-faithdome", "fearless-la-church"]),
    DiscoverableUser(id: _uid(24), name: "Christina Park",
        bio: "Registered nurse. Presbyterian. I serve on the care team at my church. Healing hands, hopeful heart.",
        denomination: "Presbyterian", city: "San Jose, CA",
        photoUrl: "https://i.pravatar.cc/300?img=11",
        coverImageUrl: "https://source.unsplash.com/800x300/?prayer,healing,hope&sig=125",
        followerCount: 234,  followingCount: 29,
        churchSlugs: ["bel-air-presbyterian-church", "immanuel-presbyterian-church", "westminster-presbyterian-church"]),
    DiscoverableUser(id: _uid(25), name: "Isaiah Mensah",
        bio: "Junior at UConn. Still figuring out my faith but I'm not running from it. Ghana roots, Connecticut raised.",
        denomination: "Non-Denominational", city: "Hartford, CT",
        photoUrl: "https://i.pravatar.cc/300?img=14",
        coverImageUrl: "https://source.unsplash.com/800x300/?faith,youth,campus&sig=126",
        followerCount: 145,  followingCount: 178,
        churchSlugs: ["oasis-church-la", "new-city-church-la"]),
    DiscoverableUser(id: _uid(26), name: "Deborah King",
        bio: "Grandmother of seven. Prayer warrior. I've been interceding for this community for 35 years and I'm not stopping now. Kansas City is in my bones.",
        denomination: "Baptist", city: "Kansas City, MO",
        photoUrl: "https://i.pravatar.cc/300?img=17",
        coverImageUrl: "https://source.unsplash.com/800x300/?prayer,intercession,hands&sig=127",
        followerCount: 1456, followingCount: 24,
        churchSlugs: ["grace-community-church", "abiding-faith-church", "eagle-rock-baptist-church"]),
    DiscoverableUser(id: _uid(27), name: "Aaron Lewis",
        bio: "High school football coach. Non-denom. I tell my players: the same discipline that wins games keeps your faith strong. Jacksonville, FL.",
        denomination: "Non-Denominational", city: "Jacksonville, FL",
        photoUrl: "https://i.pravatar.cc/300?img=20",
        coverImageUrl: "https://source.unsplash.com/800x300/?faith,strength,sunrise&sig=128",
        followerCount: 389,  followingCount: 45,
        churchSlugs: ["fearless-la-church", "core-church-la", "oasis-church"]),
    DiscoverableUser(id: _uid(28), name: "Simone Dupont",
        bio: "Chef. Catholic. I believe a table set with love is a sacrament. New Orleans born, New Orleans blessed.",
        denomination: "Catholic", city: "New Orleans, LA",
        photoUrl: "https://i.pravatar.cc/300?img=23",
        coverImageUrl: "https://source.unsplash.com/800x300/?table,community,gathering&sig=129",
        followerCount: 212,  followingCount: 33,
        churchSlugs: ["st-mary-of-the-angels-church-hollywood", "cathedral-of-our-lady-of-the-angels", "st-brendan-catholic-church"]),
    DiscoverableUser(id: _uid(29), name: "Victor Obi",
        bio: "Attorney. Non-denom. I argue for people by day and intercede for them by night. DC is my mission field.",
        denomination: "Non-Denominational", city: "Washington, DC",
        photoUrl: "https://i.pravatar.cc/300?img=26",
        coverImageUrl: "https://source.unsplash.com/800x300/?mission,city,church&sig=130",
        followerCount: 567,  followingCount: 52,
        churchSlugs: ["new-city-church-la", "union-church-of-los-angeles", "mercy-town", "tapestry-la-church"])
]

// MARK: - User posts

private let _userPosts: [UUID: [Post]] = {
    var map: [UUID: [Post]] = [:]

    func p(_ i: Int, _ content: String, type: String = "update", likes: Int, hours: Int) -> Post {
        _makePost(_uid(i), _userData[i].name, content, type, likes, hours)
    }

    // ── 0. Marcus Williams — pastor, Atlanta ──────────────────────────────
    map[_uid(0)] = [
        p(0, "Preached from Ephesians 3 this morning. 'Now to him who is able to do immeasurably more than all we ask or imagine…' I've been sitting in that verse all week. God is not limited by our expectations.", likes: 203, hours: 6),
        p(0, "Discipleship is not a program. It's a relationship that takes time, patience, and a willingness to sit with people in the middle of their mess. The church that does this well will change a city.", likes: 187, hours: 30),
        p(0, "Twenty years in ministry and I still get nervous before I preach. I think that's a good thing. It means I know I need Him.", likes: 312, hours: 72),
        p(0, "Our men's breakfast this Saturday drew 60 guys. Men are hungry for community and purpose. Give them both and watch what happens.", likes: 145, hours: 120),
        p(0, "One of my mentees preached his first full sermon yesterday. Shaky start, powerful finish. The next generation of preachers is ready. We just have to give them the mic.", likes: 289, hours: 168),
        p(0, "Read Psalm 46 this morning. 'God is our refuge and strength, an ever-present help in trouble.' Whatever you're facing this week — start here.", likes: 421, hours: 240),
        p(0, "A church that only gathers on Sunday but never scatters into its neighborhood isn't fully being the church. Both matter. We're working on both.", likes: 178, hours: 336)
    ]

    // ── 1. Priya Okafor — finance analyst, Houston ────────────────────────
    map[_uid(1)] = [
        p(1, "First time leading worship by myself tonight. Hands were shaking the whole way through. Somewhere in the second song the fear just left. God shows up when we step out.", likes: 267, hours: 4),
        p(1, "I come from a Hindu family. Every time I walk into church I'm reminded that grace found me when I wasn't even looking for it. That never stops being wild to me.", likes: 445, hours: 48),
        p(1, "No grand revelations today. Just sitting quietly with God, a cup of chai, and Psalm 139. Some mornings that's the whole sermon.", likes: 189, hours: 96),
        p(1, "Someone at work asked me why I go to church every week. I said: because every week I leave more whole than I arrived.", likes: 223, hours: 144),
        p(1, "Watching the live service from Hillsong LA right now. The worship set is everything tonight. 🙏", type: "livestream", likes: 134, hours: 2),
        p(1, "Bible study was just six of us tonight. But we went deep into Acts 2 and something shifted in the room. Small groups are underrated.", likes: 156, hours: 200),
        p(1, "A year ago I didn't know any of these people. Now I can't imagine doing life without this community. That's the church working the way it's supposed to.", likes: 312, hours: 300)
    ]

    // ── 2. James Torres — worship leader, LA ─────────────────────────────
    map[_uid(2)] = [
        p(2, "Just wrapped three hours of worship practice and I'm not even tired. That's how you know the Spirit was in the room. Something special is coming Sunday.", likes: 456, hours: 3),
        p(2, "Worship is not a performance. It's a posture. The moment I stopped trying to sound good and just started meaning it — everything changed for me.", likes: 678, hours: 24),
        p(2, "The band just learned a new original song Rachel wrote. I've heard it 40 times this week and I still get emotional at the bridge. She's anointed.", likes: 892, hours: 56),
        p(2, "LIVE right now at Angelus Temple — the room is packed and the Spirit is moving. Join online if you can't be here in person.", type: "livestream", likes: 1234, hours: 1),
        p(2, "A worship leader who doesn't pray is just a singer with a platform. I have to remind myself of that every single week.", likes: 534, hours: 100),
        p(2, "Leading worship at a youth conference this weekend. 800 young people in a room choosing to seek God. Every late night and missed weekend is worth it for moments like this.", likes: 723, hours: 160),
        p(2, "Playing guitar since I was 12. Every song I've ever written has been an argument with God or an act of surrender. Usually both.", likes: 445, hours: 220),
        p(2, "Reminder that the church is not a concert venue. If we're doing our job, people leave with more than a good feeling — they leave changed.", likes: 389, hours: 290)
    ]

    // ── 3. Angela Brooks — music teacher & worship leader, Charlotte ──────
    map[_uid(3)] = [
        p(3, "Choir practice ran two hours long tonight because nobody wanted to leave. When the music is that good, you just stay.", likes: 234, hours: 8),
        p(3, "There's a moment in every rehearsal where the group stops thinking individually and becomes one sound. I live for that moment every single week.", likes: 312, hours: 36),
        p(3, "My students asked me why I still play at church when I could be on a bigger stage. I said: the church IS the biggest stage. Still stands.", likes: 489, hours: 80),
        p(3, "Methodism gave me a deep love for hymnody and liturgy. But grace is grace whether it's sung to a pipe organ or a full drum kit.", likes: 267, hours: 130),
        p(3, "'He put a new song in my mouth, a hymn of praise to our God.' Psalm 40:3. That verse is my entire calling in one sentence.", likes: 378, hours: 190),
        p(3, "One of my 10th graders played keys in the church service this morning for the first time. She was terrified. She was magnificent. I sobbed through the whole song.", likes: 567, hours: 250),
        p(3, "Monday morning. The weekend is behind me. I'm already thinking about next Sunday's set. Some people call that obsession. I call it calling.", likes: 145, hours: 310)
    ]

    // ── 4. David Osei — seminary student, Dallas ──────────────────────────
    map[_uid(4)] = [
        p(4, "Working through Romans 5–8 in class. Paul's argument about justification and sanctification is one of the most tightly constructed things in all of Scripture.", likes: 156, hours: 12),
        p(4, "Sola Fide doesn't mean faith is all that matters. It means faith is the instrument through which grace is received. These distinctions are not academic — they're pastoral.", likes: 134, hours: 60),
        p(4, "The healthiest churches I've visited have leaders who read widely, pray deeply, and hold their opinions loosely. That combination is rarer than it should be.", likes: 203, hours: 110),
        p(4, "Hot take from homiletics class today: expository preaching forces the preacher to say things they weren't planning to say. That's a feature, not a bug.", likes: 289, hours: 170),
        p(4, "Finished Keller's 'The Reason for God' for the third time. Still devastating in the best way. Required reading for anyone who loves hard questions.", likes: 178, hours: 240),
        p(4, "My professor said the best theologians are the ones who never stopped being astonished. I want to carry that into every pulpit I ever stand in.", likes: 245, hours: 320),
        p(4, "Preached a practice sermon in class today. My professor gave me three pages of notes. I'm grateful for every word of it.", likes: 167, hours: 400)
    ]

    // ── 5. Lisa Fernandez — Catholic mom, Miami ───────────────────────────
    map[_uid(5)] = [
        p(5, "Took all three kids to Mass by myself this morning. At one point I was nursing the baby, quieting the toddler, and mouthing the Nicene Creed. God sees all of it.", likes: 567, hours: 9),
        p(5, "My oldest asked me why we pray before dinner. I said: because we don't want to forget where everything good comes from. She thought about it and said, 'okay.' That's enough for me.", likes: 734, hours: 48),
        p(5, "The Rosary is not a magic ritual. It's a rhythm that brings me back to center when everything else is noise. Twenty years of saying it and it still works.", likes: 312, hours: 100),
        p(5, "Catholic guilt is real. But so is Catholic grace. I try to live in the second one.", likes: 445, hours: 160),
        p(5, "Lit a candle for my abuela today. The communion of saints is not just a doctrine — for my family it's a lifeline.", likes: 289, hours: 230),
        p(5, "5am. Everyone asleep. Just me and a cup of coffee and the morning office. This is the only quiet I get and it is enough.", likes: 412, hours: 310),
        p(5, "My son asked if God gets tired. I said I don't think so. He said 'good, because we need a lot of help.' Out of the mouths of children. 😭", likes: 892, hours: 400)
    ]

    // ── 6. Samuel Adeyemi — evangelist, Chicago ───────────────────────────
    map[_uid(6)] = [
        p(6, "The Gospel is not a private matter. If it changed your life, you owe it to someone to say so. That's not pressure — that's love.", likes: 1456, hours: 2),
        p(6, "I'm going to say something that might be unpopular: the church needs more fire and less polish. Stop trying to make God palatable and just tell the truth.", likes: 2100, hours: 18),
        p(6, "LIVE now from New City Church. I'm in the back row and the presence in this room is THICK. Get online now if you can't be here.", type: "livestream", likes: 3400, hours: 1),
        p(6, "Preached on the streets of Chicago yesterday. Three people stopped to listen. One asked me to pray for him. That's the whole assignment.", likes: 1890, hours: 50),
        p(6, "If your faith only works on Sunday morning, it might not be faith — it might be habit. Habits are fine. Faith is better. Faith works on a Wednesday at 2pm.", likes: 1234, hours: 96),
        p(6, "My Nigerian father told me: 'God is not confused about where you're going.' I've been living off that one sentence for 10 years.", likes: 2345, hours: 150),
        p(6, "The Great Commission is not a committee suggestion. Go.", likes: 3100, hours: 210),
        p(6, "Somebody told me the church is dying. I just came from a room of 300 people worshipping like it's their last day. Please tell me more about what's dying.", likes: 2800, hours: 280)
    ]

    // ── 7. Tanya Mitchell — singer-songwriter, Nashville ──────────────────
    map[_uid(7)] = [
        p(7, "Just recorded a new song at 2am because that's when it came to me. The demo sounds rough but the anointing is on it. You'll hear it eventually.", likes: 1234, hours: 5),
        p(7, "Gospel music saved my life three times. That's not a metaphor. I can tell you exactly when each one happened.", likes: 2100, hours: 28),
        p(7, "Led worship at West Angeles this morning. That congregation has a hunger that pulls something out of you. I left empty in the best way.", likes: 1567, hours: 55),
        p(7, "The difference between performing worship and actually worshipping is whether you mean it. The room can always tell.", likes: 1890, hours: 100),
        p(7, "Working on an EP about the years I walked away from church. It's the most honest thing I've ever made. It's also the most faith-filled thing I've ever made.", likes: 2345, hours: 160),
        p(7, "Studio session with Elijah today. Two worshippers in a room together — something always happens. More coming soon.", likes: 1678, hours: 220),
        p(7, "Someone asked how I write worship songs. I said: I write songs I need to hear and trust that someone else needs them too.", likes: 1456, hours: 290),
        p(7, "Sunday is coming and I cannot wait to get back in that room. The weekend altar is the best reset I know.", likes: 1100, hours: 360)
    ]

    // ── 8. Robert Washington — deacon, Philadelphia ───────────────────────
    map[_uid(8)] = [
        p(8, "Third-generation AME. My grandfather deaconated at the same church I serve now. The weight of that never leaves me. I carry it into every Sunday.", likes: 567, hours: 15),
        p(8, "The Black church has always been more than a place of worship — a school, a courthouse, a hospital, a refuge. We carry that legacy forward every week.", likes: 1234, hours: 60),
        p(8, "Opened the church at 6am to pray. By 7am there were six other people there. Nobody planned it. The Holy Spirit keeps His own appointments.", likes: 445, hours: 108),
        p(8, "We buried a 34-year-old father of two this week. I don't have clean theology for that grief. But I know how to sit with a family that needs someone present. That's enough.", likes: 678, hours: 170),
        p(8, "Mentored a young man who said he didn't belong in church. Told him: the church is full of people who felt that way and stayed anyway. Come on in.", likes: 789, hours: 240),
        p(8, "Taught Sunday school this morning to a class of 14-year-olds. They asked better questions than most adults I've met. Don't count out the young ones.", likes: 456, hours: 320),
        p(8, "125th church anniversary next month. Four generations of the same families showing up. That kind of faithfulness doesn't happen by accident.", likes: 612, hours: 400)
    ]

    // ── 9. Grace Kim — graphic designer, Seattle ─────────────────────────
    map[_uid(9)] = [
        p(9, "Spent Sunday morning sketching instead of taking notes on the sermon. Got home and realized I'd captured everything the pastor said — just in images instead of words. God speaks in multiple languages.", likes: 456, hours: 20),
        p(9, "My faith is mostly questions with a few anchors. That's the honest version. The anchors hold while the questions do their work.", likes: 389, hours: 65),
        p(9, "Finished a commission — a watercolor mural of the crucifixion for a church in Bellevue. Wept the whole time painting it. Art is absolutely a form of prayer.", likes: 678, hours: 120),
        p(9, "There's a visual rhythm to the liturgy that nobody talks about. The way light hits stained glass at 9am. The way candles throw shadows during Advent. This is design theology.", likes: 312, hours: 180),
        p(9, "Redesigned our church bulletin this month. Small thing. But the pastor said more people are actually reading it now. Sometimes good design is pastoral care.", likes: 234, hours: 250),
        p(9, "Advent is my favorite season. Not because of the aesthetics — though the aesthetics are extraordinary — but because waiting on God is something I understand.", likes: 445, hours: 340),
        p(9, "A sermon about Bezalel from Exodus 31 this morning — the artist God filled with His Spirit to build the tabernacle. First time I've ever heard a sermon preached directly at me.", likes: 567, hours: 430)
    ]

    // ── 10. Emmanuel Asante — teacher, Minneapolis ────────────────────────
    map[_uid(10)] = [
        p(10, "Teaching high schoolers and leading a church small group are more similar than you'd think. Both require you to meet people where they are, not where you wish they were.", likes: 189, hours: 14),
        p(10, "Grew up in a Ghanaian Baptist church where the service was four hours and nobody complained. American churches at 70 minutes: 'we're running long.' I'm still adjusting.", likes: 456, hours: 58),
        p(10, "'Cast all your anxiety on him because he cares for you.' 1 Peter 5:7. Brought this verse to my classroom today. A student asked me if it was true. I said I've tested it. It is.", likes: 234, hours: 110),
        p(10, "Helped serve food at the community outreach this Saturday. Forty volunteers, 200 meals, one neighborhood a little warmer than it was before. This is what the church is for.", likes: 312, hours: 168),
        p(10, "Made it to Grace Community Church this Sunday. The worship was different from what I grew up with but the presence was the same. God doesn't have an accent.", likes: 178, hours: 230),
        p(10, "Praying for my students by name. Seventeen of them. Some of them are going through things no kid should have to face. The church should be the first place they'd turn.", likes: 267, hours: 310),
        p(10, "Faith and patience are inseparable. I learned that from my father in Ghana and I relearn it every semester in the classroom.", likes: 145, hours: 400)
    ]

    // ── 11. Keisha Thompson — NICU nurse, New Orleans ─────────────────────
    map[_uid(11)] = [
        p(11, "A baby came in at 24 weeks this week. The parents were devastated. Today that baby squeezed my finger. I cannot explain what I believe in clinical terms. But I've watched too many miracles to call them coincidences.", likes: 789, hours: 10),
        p(11, "I pray before every shift. Not because it fixes everything. Because I need to walk into that NICU knowing I'm not doing it alone.", likes: 345, hours: 50),
        p(11, "Mass was quiet this morning. Just me and a handful of early risers. Those small, ordinary Masses are sometimes the holiest ones.", likes: 212, hours: 105),
        p(11, "Someone asked me how I keep faith after seeing so much suffering. I said: I keep faith because I've also seen so much survival. Both are real. Both are God's.", likes: 567, hours: 170),
        p(11, "Held the hand of a mother who'd just lost her baby. Didn't say a word. Just stayed. Some ministry doesn't have words.", likes: 892, hours: 240),
        p(11, "The church feeds my neighbors every Wednesday night. I bring food from my kitchen. That meal is the most sacramental thing that happens in my week.", likes: 278, hours: 320),
        p(11, "New Orleans Catholic culture is its own thing. The music, the food, the ritual, the grief, the joy — all of it tangled together. I wouldn't trade it.", likes: 345, hours: 410)
    ]

    // ── 12. Nathan Pierce — youth pastor, Denver ─────────────────────────
    map[_uid(12)] = [
        p(12, "Youth group tonight: 40 teenagers, 1 hour, and a real conversation about why God allows suffering. They asked questions I still don't have clean answers to. I love this job.", likes: 567, hours: 7),
        p(12, "The student who told me church was boring last year just asked if he could help lead a small group. I had to excuse myself so he wouldn't see me cry.", likes: 1234, hours: 45),
        p(12, "Youth pastors: stop trying to be cool. Be consistent. Teenagers can detect authenticity and they will trust a sincere dork over a polished performer every time.", likes: 892, hours: 95),
        p(12, "Three students got baptized this weekend. All the bad coffee and late nights and awkward lock-ins — all of it is for that moment. All of it.", likes: 1567, hours: 155),
        p(12, "Every generation says the next one is lost. Every generation has been wrong. These kids have more faith and more questions than we did. That's not a problem — that's the future.", likes: 734, hours: 215),
        p(12, "Ran into one of my former students today. He's 22, leading a small group of his own. I just stood there trying not to embarrass myself in the parking lot.", likes: 1100, hours: 290),
        p(12, "Some weeks youth ministry feels like talking into a void. Then a parent texts to say their kid asked to say grace at dinner. That's why you stay.", likes: 678, hours: 380)
    ]

    // ── 13. Destiny Owens — entrepreneur, Detroit ─────────────────────────
    map[_uid(13)] = [
        p(13, "The same faith that carried me through bankruptcy got me to seven figures. God is not intimidated by your ambitions. He wrote them.", likes: 1456, hours: 6),
        p(13, "I run my business meetings with the same intentionality I bring to prayer. Expectation, gratitude, presence. The outcomes in both rooms have been remarkable.", likes: 1100, hours: 40),
        p(13, "The 5am prayer before I launch a product is not superstition. It's alignment. I need to know my goals are His goals before I spend money on them.", likes: 890, hours: 85),
        p(13, "Pentecostal women have been building enterprises long before it was trending. We just called it anointing instead of hustle.", likes: 1678, hours: 140),
        p(13, "My mentor told me: stop praying for God to bless your plan and start praying to understand His plan. That cost me three years to learn. Don't be me.", likes: 2100, hours: 200),
        p(13, "At West Angeles this morning. That congregation carries an anointing that doesn't feel manufactured. You can tell when people have actually been through something.", likes: 789, hours: 270),
        p(13, "Purpose is not a side effect of your career. It's the engine. Get that right and everything else starts to make sense.", likes: 1234, hours: 350)
    ]

    // ── 14. Carlos Reyes — construction foreman, San Antonio ─────────────
    map[_uid(14)] = [
        p(14, "Prayed with my whole crew before we broke ground on a new job today. Seven guys, hard hats off, heads bowed. Some of them don't go to church. They all bowed their heads.", likes: 678, hours: 11),
        p(14, "Sunday Mass with my family. Four kids in one pew. My wife holding the baby. Me trying not to fall asleep. And somehow God still meets us there. Every time.", likes: 345, hours: 55),
        p(14, "Taught my son the Our Father in Spanish this week. My father taught me. His father taught him. Some things you don't let go of.", likes: 456, hours: 110),
        p(14, "Hard week on the job. Lost a subcontract, three things broke at once. Sat with Psalm 121 on the drive home. 'My help comes from the Lord, the Maker of heaven and earth.' Still true.", likes: 289, hours: 175),
        p(14, "My parish does a blessing of the tools every October. People think it's old-fashioned. I think it's the most honest thing we do all year. Everything I work with is consecrated.", likes: 234, hours: 245),
        p(14, "Took my daughter to her first confession. She was nervous. I told her: God already knows. You're just saying it out loud. She came out lighter. That's grace.", likes: 512, hours: 320),
        p(14, "The men I work with are good men who are looking for something they can't name. I try to be the answer to that without making it weird. Just show up. Do good work. Be consistent.", likes: 378, hours: 410)
    ]

    // ── 15. Abigail Johnson — student, Atlanta ────────────────────────────
    map[_uid(15)] = [
        p(15, "Campus ministry tonight drew 90 students. 90. On a Tuesday. I need people to stop saying Gen Z doesn't care about faith.", likes: 1200, hours: 5),
        p(15, "Theology class is destroying and rebuilding my faith at the same time. My professor calls it deconstruction. I call it getting honest. Either way I'm not the same.", likes: 890, hours: 35),
        p(15, "My roommate became a Christian last week. She didn't come to a service or an event. She just watched how I handled a really hard week and asked me to explain. Be the sermon.", likes: 2300, hours: 70),
        p(15, "Grace Community Church this Sunday. The message on forgiveness was exactly what I needed and also extremely inconvenient timing. God is not subtle.", likes: 456, hours: 125),
        p(15, "Led Bible study tonight. Topic: does God care about justice? Spoiler: yes. The room got heated. That's how you know you're in the right passage.", likes: 678, hours: 185),
        p(15, "Senior year. Graduation in three months. Terrified. Excited. Trusting. Jeremiah 29:11 is doing a lot of heavy lifting right now.", likes: 934, hours: 250),
        p(15, "The Spelman chapel at dawn is one of the most holy places I've ever been in. Not because of the architecture. Because of what women have prayed there for over 100 years.", likes: 1456, hours: 330),
        p(15, "Intern interviews start next week. Praying over every application. My GPA is good but God is better. Both matter.", likes: 567, hours: 420)
    ]

    // ── 16. Joshua Bennett — software engineer, Portland ─────────────────
    map[_uid(16)] = [
        p(16, "Debugging code for three hours this afternoon and I kept thinking about how God never gets frustrated when He's working on me. Infinite patience. I don't have that. He does.", likes: 456, hours: 9),
        p(16, "The church I go to here in Portland is small and imperfect and I love it. Not despite the messiness. Because of it. Perfection is a red flag.", likes: 312, hours: 48),
        p(16, "Working through Acts on lunch breaks. Luke writes about the early church like a journalist who can't believe what he's witnessing. That energy is contagious.", likes: 234, hours: 100),
        p(16, "Went to Oasis Church this morning for the first time. Different style than what I'm used to. Same Spirit. That keeps being true everywhere I go.", likes: 189, hours: 162),
        p(16, "Some people think logic and faith are opposites. I'm an engineer who prays every morning. Hardest problem I've ever worked on: letting go of control. Faith is the solution I keep coming back to.", likes: 567, hours: 230),
        p(16, "'Come to me, all you who are weary and burdened, and I will give you rest.' Matthew 11:28. Said this out loud to myself at 11pm on a project deadline. Still true at 11pm.", likes: 389, hours: 310),
        p(16, "Volunteered to rebuild my church's website this month. Pro bono. It took three weekends. Worth every hour.", likes: 178, hours: 400)
    ]

    // ── 17. Patricia Nwosu — nonprofit director, Silver Spring ───────────
    map[_uid(17)] = [
        p(17, "Faith without works is dead. James 2:17. This is not a suggestion for nonprofits — it's a job description.", likes: 678, hours: 8),
        p(17, "Secured a major grant today for our after-school program. Kneeled in my office and said thank you before I sent a single email. Get the sequence right.", likes: 892, hours: 40),
        p(17, "Nigerian churches taught me that prayer is labor. You don't mumble it — you work it. I've carried that into every strategy meeting I've ever run.", likes: 567, hours: 88),
        p(17, "The church should be the most practical institution in any city. Housing. Jobs. Food. Community. We have the theology AND the infrastructure. We just have to show up.", likes: 1100, hours: 150),
        p(17, "Burned out last November. Took two weeks off. Came back with the clearest vision I've had in years. Rest is not laziness — it's maintenance.", likes: 789, hours: 220),
        p(17, "Attended a service at New City Church this weekend. They had a whole section on justice in the sermon. As a nonprofit worker I wanted to stand up and cheer.", likes: 345, hours: 300),
        p(17, "I pray for my team by name every morning. Not just for their productivity. For their families, their health, their hearts. Leadership is intercession.", likes: 567, hours: 390)
    ]

    // ── 18. Michael Torres — retired chaplain, Phoenix ────────────────────
    map[_uid(18)] = [
        p(18, "Forty years of military service. The thing I'm most proud of is not a rank or a commendation. It's the conversations I had with soldiers the night before everything changed for them.", likes: 678, hours: 16),
        p(18, "The desert teaches you to be present. There is nothing else to do. I moved to Phoenix on purpose. The stillness here still does something to me.", likes: 312, hours: 65),
        p(18, "Morning prayer from the Episcopal liturgy: 'Lord, open our lips, and our mouth shall proclaim your praise.' I've said this every morning for thirty years. Still the right way to start a day.", likes: 245, hours: 120),
        p(18, "Combat chaplaincy changed how I read every psalm of lament. David wasn't performing grief. He was doing the only honest thing available to him. That's what those psalms are for.", likes: 567, hours: 185),
        p(18, "Led a veteran's Bible study this week. Six men, all carrying things they don't talk about anywhere else. The church is one of the last spaces where that's allowed.", likes: 789, hours: 260),
        p(18, "Took communion this morning and thought about every soldier I've given last rites to. That table is bigger than we realize.", likes: 456, hours: 340),
        p(18, "Retired doesn't mean done. It means I serve differently now. Slower. More patient. More sure of what matters and what doesn't.", likes: 389, hours: 430)
    ]

    // ── 19. Blessing Adebayo — social worker, Columbus ────────────────────
    map[_uid(19)] = [
        p(19, "One of my clients got housed today after 18 months of working together. She called me crying. I called her back crying. We figured out how to get her furniture tomorrow. This is the work.", likes: 892, hours: 6),
        p(19, "Methodist theology has a phrase: 'works of mercy.' It's the entire job description for social work. I didn't realize until seminary that what I do is ancient.", likes: 456, hours: 45),
        p(19, "Praying for the people who fall through every system we build. The ones the programs never quite reach. God sees them. I'm trying to see them too.", likes: 567, hours: 100),
        p(19, "Our church does a community dinner every Thursday. Sixty people around tables. Different backgrounds, different struggles, one shared meal. That's the Kingdom.", likes: 734, hours: 165),
        p(19, "'He has shown you, O mortal, what is good. And what does the Lord require of you? To act justly and to love mercy and to walk humbly with your God.' Micah 6:8. The whole assignment.", likes: 678, hours: 235),
        p(19, "Compassion fatigue is real. I've learned to refill before I'm empty. Sunday morning is one of the ways I do that. I need the community as much as my clients do.", likes: 489, hours: 315),
        p(19, "You can't out-give God. I tested this theory aggressively in my 20s. He kept proving me wrong. Eventually I stopped testing.", likes: 345, hours: 410)
    ]

    // ── 20. Sarah Chen — artist, Brooklyn ────────────────────────────────
    map[_uid(20)] = [
        p(20, "Painted from Revelation 21 this week. Trying to find a color for 'He will wipe every tear from their eyes.' There is no color for that. I tried anyway.", likes: 789, hours: 14),
        p(20, "Art that doesn't ask hard questions isn't art. Faith that doesn't wrestle with doubt isn't faith. I'm trying to do both at the same time all the time.", likes: 567, hours: 58),
        p(20, "Someone bought my painting of Gethsemane and said it was the first time they'd ever cried in front of a painting. That moment is why I do this.", likes: 1100, hours: 105),
        p(20, "In my tradition beauty is a form of argument for God. I believe this completely. I'm building the case one canvas at a time.", likes: 890, hours: 165),
        p(20, "Visited St. Patrick's Cathedral on a Tuesday afternoon. Just sat there for an hour. I didn't pray in words. I just let the space do what space does.", likes: 678, hours: 230),
        p(20, "Starting a new series inspired by the Psalms. One painting per psalm. 150 paintings. I'm giving myself a year. Or five. Time is different when you're making something sacred.", likes: 1234, hours: 310),
        p(20, "Someone asked me what denomination I am. I said I'm a follower of Jesus who can't stop making things. They said 'that's not a denomination.' I said 'give it time.'", likes: 567, hours: 400)
    ]

    // ── 21. Daniel Okonkwo — associate pastor, Richmond ──────────────────
    map[_uid(21)] = [
        p(21, "Preached my first solo sermon at 23. Forgot half my notes, lost my place twice, cried once. A feedback card someone left said: 'keep going, God is in this.' I've kept that card.", likes: 678, hours: 10),
        p(21, "A sermon is not a lecture. It's an invitation. If people leave unchanged, something went wrong — and it might not be in the room.", likes: 456, hours: 55),
        p(21, "Discipleship is a long conversation. The best pastors I know are the ones still having theirs.", likes: 389, hours: 108),
        p(21, "Baptized my first congregant today. She's 71 years old. Said she'd been meaning to do it for 40 years and kept putting it off. It is never, ever too late.", likes: 1234, hours: 170),
        p(21, "The sermon I'm most nervous to preach is usually the one I most need to hear. That tension is almost always a sign to preach it anyway.", likes: 567, hours: 230),
        p(21, "Sat with an older pastor for two hours today just listening. No agenda. No notebook. Just receiving. The church needs more of that kind of mentorship.", likes: 489, hours: 310),
        p(21, "Grace Community Church's senior pastor said something in a meeting last week that I'm still thinking about: 'Your congregation will go as deep as you go.' That's a weight worth carrying.", likes: 712, hours: 400)
    ]

    // ── 22. Hope Martinez — teacher, Albuquerque ─────────────────────────
    map[_uid(22)] = [
        p(22, "A student asked me today if God is real. I'm a public school teacher so I said 'that's a great question to explore with your family.' But I went to my car and prayed for her.", likes: 456, hours: 12),
        p(22, "My daughter asked why Jesus had to die. I gave her a five-minute answer. She said 'because He loved us?' I said yes. She figured out the whole theology. Kids are incredible.", likes: 789, hours: 55),
        p(22, "Sunday Mass with both kids. Emmanuel (age 6) received his first communion this month. The look on his face when he came back to the pew is the most beautiful thing I've ever seen.", likes: 1100, hours: 110),
        p(22, "The Rosary group at our parish has nine women and one man. We've been meeting every Wednesday for four years. Some weeks it's the only hour I feel fully at rest.", likes: 312, hours: 175),
        p(22, "My daughter's quinceañera is in three months. Planning it alongside her has been one of the most spiritual things I've done as a mother. Ritual matters. Rites of passage matter.", likes: 567, hours: 245),
        p(22, "Taught my class a poem that uses Psalm 23 as its backbone. Not a religious lesson — just literature. But three students came up after to ask me about it. God always finds a way.", likes: 345, hours: 330),
        p(22, "My son said grace at dinner tonight without being asked. Just started praying. My husband and I looked at each other across the table and didn't say a word.", likes: 892, hours: 420)
    ]

    // ── 23. Elijah Freeman — musician, Baltimore ──────────────────────────
    map[_uid(23)] = [
        p(23, "Produced a worship track at midnight because the melody wouldn't let me sleep. Some songs demand to be born at inconvenient hours. You learn to answer the door.", likes: 567, hours: 3),
        p(23, "Music is how I argue with God and agree with Him in the same breath. Therapy is cheaper. Music is richer. I need both.", likes: 789, hours: 45),
        p(23, "Baltimore has streets that will harden you fast if you let them. Worship kept my heart soft when I was 19 and had no reason to trust anyone. That's not small.", likes: 678, hours: 90),
        p(23, "In the studio with Tanya today. Two worshippers in a room — something always emerges. More soon.", likes: 1100, hours: 150),
        p(23, "Writing a piece based on Lamentations 3. 'Because of the Lord's great love we are not consumed.' The most hope I've ever found came from the most honest grief I've ever read.", likes: 567, hours: 215),
        p(23, "Played a Sunday set at a church in DC I'd never visited before. Didn't know the room. Didn't know the team. By the second song we were completely in sync. That's the Spirit.", likes: 789, hours: 290),
        p(23, "Music is not a gift I own. It's one I steward. Some weeks I feel that more than others. This week I feel it very clearly.", likes: 456, hours: 380)
    ]

    // ── 24. Christina Park — nurse, San Jose ─────────────────────────────
    map[_uid(24)] = [
        p(24, "Prayed with a patient before surgery today. She asked me to. When I finished she said 'thank you, that's the most prepared I've felt.' That stays with you.", likes: 567, hours: 11),
        p(24, "Reformed theology gave me a framework for suffering that I rely on every single shift. God is sovereign and He is good. Both. At the same time. In the ICU.", likes: 312, hours: 52),
        p(24, "Grew up in a Korean church where Sunday ran until 2pm and you didn't complain. I'm Presbyterian now in a church that's done by noon. Still adjusting to the silence.", likes: 278, hours: 105),
        p(24, "The Lord's Supper this morning. Every time I hold that cup I think about the patients I've lost and the ones I've watched survive. Both belong at that table.", likes: 456, hours: 168),
        p(24, "Read Psalm 91 before my night shift last week. 'He will command his angels concerning you to guard you in all your ways.' I take that as a professional courtesy.", likes: 789, hours: 240),
        p(24, "Sabbath is not optional for me anymore. I tried skipping it for years. My body and my faith both collapsed. Now it's protected time. Non-negotiable.", likes: 567, hours: 320),
        p(24, "Church potluck this Sunday. Someone brought Korean fried chicken. Someone else brought tamales. A third person brought jollof rice. The table of the Lord feeds everyone.", likes: 1234, hours: 410)
    ]

    // ── 25. Isaiah Mensah — student, Hartford ────────────────────────────
    map[_uid(25)] = [
        p(25, "Honest post: I went through a season where I wasn't sure I believed any of this anymore. I'm still here. Still asking. Still showing up. That might be its own kind of faith.", likes: 1234, hours: 8),
        p(25, "Found a church here in Hartford that doesn't feel like it's performing for me. The pastor just preaches the text. No smoke machine. No light show. Just the Word. I needed that.", likes: 456, hours: 45),
        p(25, "Ghanaian church vs. American church is a study in contrasts. Back home they clap on every beat. Here they apologize for running five minutes over. Both are church. Both have God.", likes: 789, hours: 100),
        p(25, "Prayed for something specific for two years. The answer came in a completely different form than I expected. Took me three months to recognize it. God is not late. He's just not what I planned.", likes: 912, hours: 165),
        p(25, "Campus fellowship tonight felt different. Usually I'm half-distracted. Tonight I was completely present. I don't know what changed. Maybe I just finally stopped resisting.", likes: 345, hours: 235),
        p(25, "Asking big questions about faith doesn't make you faithless. It makes you honest. I'm done pretending I have certainty I don't have. Turns out the church has room for that too.", likes: 678, hours: 320),
        p(25, "Read Hebrews 11 tonight. 'Faith is confidence in what we hope for and assurance about what we do not see.' I've been reading that as a requirement. Tonight it felt like an invitation.", likes: 890, hours: 420),
        p(25, "God found me at a really inconvenient time in my life. Senior year of high school. Scholarship pressure. Family expectations. He showed up anyway. I'm still processing that.", likes: 567, hours: 520)
    ]

    // ── 26. Deborah King — grandmother, Kansas City ───────────────────────
    map[_uid(26)] = [
        p(26, "Been praying for this city for 35 years. I've watched neighborhoods fall apart and come back. God is patient. So am I. That's the only strategy I know.", likes: 1890, hours: 12),
        p(26, "My granddaughter asked me why I pray out loud. I told her: so you know you can too. The next generation learns to pray by watching.", likes: 2345, hours: 55),
        p(26, "Sunday morning. Coffee. Isaiah 40. 'Those who hope in the Lord will renew their strength.' Thirty-five years of evidence behind that verse.", likes: 3100, hours: 100),
        p(26, "The intercessors in this community are the backbone of everything. You may never see us on a stage. We're not here for a stage.", likes: 1567, hours: 160),
        p(26, "I prayed for my son's salvation for 18 years. He got baptized last month. Parents — hold on. Do not give up. God is listening.", likes: 4500, hours: 220),
        p(26, "Prayer is not begging. It's conversation. I've been having this conversation for decades and I'm still not done. He's never tired of it either.", likes: 2100, hours: 295),
        p(26, "Seven grandchildren. All of them know the Lord. That's not luck. That's a family that chose to make the Kingdom the inheritance. Start early. Don't stop.", likes: 3400, hours: 380)
    ]

    // ── 27. Aaron Lewis — football coach, Jacksonville ────────────────────
    map[_uid(27)] = [
        p(27, "Told my team before the game: play like you have nothing to prove and everything to give. That's a sermon and a game plan at the same time.", likes: 678, hours: 7),
        p(27, "Team prayer before and after every practice. Some of my players have never prayed out loud before. By week six they're leading it. That's growth. On and off the field.", likes: 456, hours: 42),
        p(27, "Sunday service then straight to film review. I know that sounds like I'm missing the message. But I think about the sermon on the way to work every Monday. Nothing is wasted.", likes: 234, hours: 95),
        p(27, "The discipline required to play at a high level is the same discipline required to follow Jesus consistently. Early mornings. Repetition. Showing up when you don't feel like it.", likes: 892, hours: 155),
        p(27, "'Run in such a way as to get the prize.' 1 Corinthians 9:24. I've quoted this verse in every pre-game speech for the last six years. Still landing.", likes: 567, hours: 225),
        p(27, "Mentoring a young man who lost his dad last year. He plays football but that's not why I'm in his corner. He needs a man to show him what faithfulness looks like. I can do that.", likes: 1100, hours: 305),
        p(27, "Sunday with my family. No football. No playbooks. Just church, lunch, and a long walk. Rest is part of the training.", likes: 345, hours: 400)
    ]

    // ── 28. Simone Dupont — chef, New Orleans ─────────────────────────────
    map[_uid(28)] = [
        p(28, "Cooked for 80 people at a church fundraiser tonight. Standing in that kitchen for five hours, feeding people I love — I don't know a more complete form of worship.", likes: 567, hours: 9),
        p(28, "A table set with care is a form of love. A meal made with intention is a form of prayer. I've believed this my whole life. New Orleans taught me it was true.", likes: 445, hours: 50),
        p(28, "Ash Wednesday Mass this morning before my shift. Walked back into the kitchen with a cross on my forehead. My sous chef asked about it. Good conversation.", likes: 312, hours: 103),
        p(28, "Lenten season and I gave up something I actually like this year. Not as an exercise in willpower. As a reminder that the best things are worth the wait.", likes: 234, hours: 168),
        p(28, "Made my grandmother's gumbo for a church potluck. Recipe unchanged for 70 years. Community food is memory food is sacred food. All three at once.", likes: 789, hours: 245),
        p(28, "People think being a chef and being Catholic is separate. Eucharist is a meal. Fellowship is a table. I've been doing sacramental work my whole life and didn't have the language for it until I did.", likes: 567, hours: 330),
        p(28, "New Orleans is its own theology. The death and the joy and the music and the food all together, all the time. Mardi Gras into Ash Wednesday. You can't have the resurrection without the cross.", likes: 890, hours: 420)
    ]

    // ── 29. Victor Obi — attorney, Washington DC ──────────────────────────
    map[_uid(29)] = [
        p(29, "Argued before a federal judge today. Housing discrimination case. Before I walked in I prayed for the families in those files — not the legal outcome, the people.", likes: 567, hours: 9),
        p(29, "Justice is a theological concept before it's a legal one. The church should be its loudest advocate. Not partisan — prophetic.", likes: 890, hours: 52),
        p(29, "DC is a city that worships power. I live here to remind myself and anyone who will listen that the most powerful thing in this city is not in any building on Pennsylvania Avenue.", likes: 734, hours: 110),
        p(29, "Reading Micah 6:8 before every court appearance. Act justly. Love mercy. Walk humbly. That's the whole practice. Everything else is execution.", likes: 456, hours: 175),
        p(29, "Won a pro bono case today. Single mother. Wrongful eviction. She gets to keep her apartment. I've won bigger cases. None have felt bigger than this.", likes: 1234, hours: 250),
        p(29, "A colleague asked me how I stay motivated in a system that fails people constantly. I said: I don't work for the system. I work for the people. Faith gives you a longer horizon than law does.", likes: 789, hours: 340),
        p(29, "Attended Mercy Town this Sunday. The sermon was about Daniel — a man of faith navigating empire. I took three pages of notes and felt personally seen.", likes: 567, hours: 430)
    ]

    return map
}()

// MARK: - Social graph (computed from shared signals)
//
// Follows are derived programmatically — not hardcoded — so the graph stays
// coherent if users or church slugs change. Four weighted signals determine
// who follows whom:
//   1. Church overlap   — shared church slugs (+2 / +5 / +9)
//   2. Denomination     — same tradition (+4), adjacent tradition (+2 / +1)
//   3. City / metro     — same city (+5), metro cluster (+3), same state (+1)
//   4. Hub attraction   — high-follower accounts are more discoverable (+1–3)
//
// Each user has a follow budget that controls connection density.
// Ties are broken by a deterministic hash so results are stable across runs.

private let _followGraph: [UUID: [UUID]] = {

    // ── Signal scorers ────────────────────────────────────────────────────

    func churchOverlap(_ a: DiscoverableUser, _ b: DiscoverableUser) -> Int {
        let shared = Set(a.churchSlugs).intersection(Set(b.churchSlugs)).count
        switch shared {
        case 1:  return 2
        case 2:  return 5
        default: return shared >= 3 ? 9 : 0
        }
    }

    // evangelical: charismatic / Black-Protestant tradition
    // mainline:    confessional / liturgical Protestant
    // liturgical:  sacramental traditions
    // Uses max() so AME (which appears in two groups) scores correctly.
    func denomAffinity(_ a: String?, _ b: String?) -> Int {
        guard let a = a, let b = b else { return 0 }
        if a == b { return 4 }
        let evangelical = Set(["Baptist", "AME", "Pentecostal", "Non-Denominational"])
        let mainline    = Set(["Methodist", "Presbyterian", "Lutheran", "Episcopal", "AME"])
        let liturgical  = Set(["Catholic", "Orthodox", "Episcopal"])
        var score = 0
        if evangelical.contains(a) && evangelical.contains(b) { score = max(score, 2) }
        if mainline.contains(a)    && mainline.contains(b)    { score = max(score, 2) }
        if liturgical.contains(a)  && liturgical.contains(b)  { score = max(score, 1) }
        return score
    }

    func cityAffinity(_ a: String?, _ b: String?) -> Int {
        guard let a = a, let b = b else { return 0 }
        let partsA = a.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let partsB = b.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let cityA  = partsA.first ?? a
        let cityB  = partsB.first ?? b
        let stateA = partsA.count > 1 ? partsA[1] : ""
        let stateB = partsB.count > 1 ? partsB[1] : ""
        if cityA == cityB { return 5 }
        // Known metro / regional clusters
        let dcMetro   = Set(["Silver Spring", "Washington", "Baltimore"])
        let southeast = Set(["Atlanta", "Charlotte", "Richmond", "Nashville"])
        if dcMetro.contains(cityA)   && dcMetro.contains(cityB)   { return 3 }
        if southeast.contains(cityA) && southeast.contains(cityB) { return 2 }
        if !stateA.isEmpty && stateA == stateB                    { return 1 }
        return 0
    }

    // More-followed accounts are more discoverable platform-wide.
    func hubBonus(_ user: DiscoverableUser) -> Int {
        switch user.followerCount {
        case 1500...: return 3
        case 800...:  return 2
        case 400...:  return 1
        default:      return 0
        }
    }

    func followScore(from f: DiscoverableUser, to t: DiscoverableUser) -> Int {
        churchOverlap(f, t)
        + denomAffinity(f.denomination, t.denomination)
        + cityAffinity(f.city, t.city)
        + hubBonus(t)
    }

    // ── Follow budgets ────────────────────────────────────────────────────
    // How many seed-users this person actively follows (a subset of their
    // total platform followingCount, which also includes churches and future
    // real users). Tuned to reflect each person's engagement style.
    let budgets: [Int: Int] = [
         0: 5,    // Marcus  — mentorship-focused pastor
         1: 9,    // Priya   — active explorer, worship volunteer
         2: 6,    // James   — worship community
         3: 5,    // Angela  — Methodist circle + hubs
         4: 4,    // David   — theologically selective seminary student
         5: 3,    // Lisa    — light Catholic user
         6: 11,   // Samuel  — widest-reaching evangelist
         7: 7,    // Tanya   — gospel music network
         8: 5,    // Robert  — AME tradition
         9: 7,    // Grace   — curious artist
        10: 4,    // Emmanuel — quiet, selective
        11: 3,    // Keisha  — light NICU nurse
        12: 6,    // Nathan  — Lutheran youth pastor
        13: 7,    // Destiny — entrepreneurial network
        14: 2,    // Carlos  — very light user
        15: 10,   // Abigail — most active student
        16: 6,    // Joshua  — engineer, moderate
        17: 6,    // Patricia — nonprofit director
        18: 3,    // Michael — selective retired chaplain
        19: 4,    // Blessing — social worker
        20: 8,    // Sarah   — curious artist
        21: 6,    // Daniel  — associate pastor
        22: 3,    // Hope    — light user
        23: 7,    // Elijah  — musician, DC-area connections
        24: 4,    // Christina — nurse
        25: 6,    // Isaiah  — seeking student
        26: 3,    // Deborah — elder, minimal tech footprint
        27: 5,    // Aaron   — coach
        28: 4,    // Simone  — chef
        29: 6     // Victor  — attorney
    ]

    let threshold = 3   // minimum score required to follow someone
    var result: [UUID: [UUID]] = [:]

    for i in 0..<_userData.count {
        let user   = _userData[i]
        let budget = budgets[i] ?? 5

        var candidates: [(idx: Int, score: Int)] = []
        for j in 0..<_userData.count where j != i {
            let s = followScore(from: user, to: _userData[j])
            if s >= threshold { candidates.append((idx: j, score: s)) }
        }

        // Primary sort: score descending.
        // Tie-break: deterministic hash of (candidate index, follower index)
        // so results are stable across runs with no randomness.
        candidates.sort {
            if $0.score != $1.score { return $0.score > $1.score }
            let tieA = ($0.idx * 17 + i * 31) % 29
            let tieB = ($1.idx * 17 + i * 31) % 29
            return tieA < tieB
        }

        result[_uid(i)] = candidates.prefix(budget).map { _uid($0.idx) }
    }

    return result
}()

// MARK: - Church follow graph (userId → [slugs])

private let _churchFollowGraph: [UUID: [String]] = {
    var dict: [UUID: [String]] = [:]
    for user in _userData { dict[user.id] = user.churchSlugs }
    return dict
}()

// MARK: - Helpers

private func _uid(_ index: Int) -> UUID {
    let key = "seed-user-\(index)"
    var hash = key.utf8.reduce(UInt64(0x811c9dc5)) { ($0 ^ UInt64($1)) &* 0x01000193 }
    var bytes = [UInt8](repeating: 0, count: 16)
    for i in 0..<8 { bytes[i] = UInt8(hash & 0xFF); hash >>= 8 }
    hash = key.utf8.reduce(UInt64(0xcbf29ce484222325)) { ($0 ^ UInt64($1)) &* 0x100000001b3 }
    for i in 8..<16 { bytes[i] = UInt8(hash & 0xFF); hash >>= 8 }
    bytes[6] = (bytes[6] & 0x0F) | 0x40
    bytes[8] = (bytes[8] & 0x3F) | 0x80
    return UUID(uuid: (bytes[0],bytes[1],bytes[2],bytes[3],bytes[4],bytes[5],bytes[6],bytes[7],
                       bytes[8],bytes[9],bytes[10],bytes[11],bytes[12],bytes[13],bytes[14],bytes[15]))
}

private func _makePost(_ id: UUID, _ name: String, _ content: String,
                        _ type: String, _ likes: Int, _ hours: Int) -> Post {
    Post(
        id: MockDataProvider.deterministicUUID(for: "\(name)-post-\(hours)"),
        authorId: id,
        authorName: name,
        authorType: "worshipper",
        content: content,
        photoUrl: nil,
        videoUrl: nil,
        postType: type,
        likeCount: likes,
        createdAt: Date().addingTimeInterval(TimeInterval(-hours * 3600)),
        isLiked: false
    )
}
