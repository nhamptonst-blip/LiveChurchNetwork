import Foundation

class CacheManager {
    static let shared = CacheManager()

    private let cache = NSCache<NSString, CacheEntry>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("LiveChurchNetworkCache")

        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }

        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB memory cache
    }

    // MARK: - Generic Caching

    func cached<T: Codable>(
        key: String,
        expiration: TimeInterval = 3600, // 1 hour default
        fetch: @escaping () async throws -> T
    ) async throws -> T {
        // Check memory cache first
        if let entry = cache.object(forKey: key as NSString) {
            if !entry.isExpired {
                if let cachedData = entry.data,
                   let value = try? JSONDecoder().decode(T.self, from: cachedData) {
                    return value
                }
            } else {
                cache.removeObject(forKey: key as NSString)
            }
        }

        // Fetch fresh data
        let value = try await fetch()

        // Store in cache
        if let encoded = try? JSONEncoder().encode(value) {
            let entry = CacheEntry(data: encoded, expiration: expiration)
            cache.setObject(entry, forKey: key as NSString, cost: encoded.count)
        }

        return value
    }

    func invalidateCache(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    func clearAllCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Specific Cache Keys

    static let churchesListCacheKey = "churches_list"
    static let peopleCacheKey = "people_list"
    static let profileCacheKeyPrefix = "profile_"
    static let churchSubmissionCacheKeyPrefix = "church_submission_"

    func cacheKey(forProfileId id: UUID) -> String {
        "\(Self.profileCacheKeyPrefix)\(id)"
    }

    func cacheKey(forChurchSubmissionId id: UUID) -> String {
        "\(Self.churchSubmissionCacheKeyPrefix)\(id)"
    }
}

// MARK: - Cache Entry

private class CacheEntry {
    let data: Data?
    let timestamp: Date
    let expiration: TimeInterval

    init(data: Data?, expiration: TimeInterval) {
        self.data = data
        self.timestamp = Date()
        self.expiration = expiration
    }

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > expiration
    }
}
