import Foundation
import SwiftUI

/// Performance configuration for the app
struct PerformanceConfig {
    // MARK: - Pagination
    /// Items to load per page in list views
    static let itemsPerPage = 20

    /// Threshold for triggering next page load (percentage from end)
    static let paginationThreshold = 0.8

    // MARK: - Image Loading
    /// Enable image caching (uses URLSession)
    static let enableImageCaching = true

    /// Maximum concurrent image downloads
    static let maxConcurrentImageDownloads = 4

    // MARK: - API Response Caching
    /// Cache expiration time for churches list (seconds)
    static let churchesListCacheExpiration: TimeInterval = 300 // 5 minutes

    /// Cache expiration time for people list (seconds)
    static let peopleCacheExpiration: TimeInterval = 300 // 5 minutes

    /// Cache expiration time for profile data (seconds)
    static let profileCacheExpiration: TimeInterval = 600 // 10 minutes

    /// Cache expiration time for church submissions (seconds)
    static let churchSubmissionCacheExpiration: TimeInterval = 600 // 10 minutes

    // MARK: - Rendering Optimization
    /// Lazy grid should load items as user scrolls
    static let lazyGridLoadingEnabled = true

    /// Number of items to preload ahead of visible area
    static let preloadAheadCount = 5

    // MARK: - Memory Management
    /// Maximum concurrent tasks for data loading
    static let maxConcurrentTasks = 3

    /// Enable aggressive memory warnings handling
    static let enableMemoryWarnings = true

    // MARK: - Network Optimization
    /// Network request timeout (seconds)
    static let networkTimeout: TimeInterval = 30

    /// Enable request deduplication
    static let enableRequestDeduplication = true

    /// Debounce search input (seconds)
    static let searchDebounceTime: TimeInterval = 0.5
}

// MARK: - View Extensions for Performance

extension View {
    /// Optimizes list rendering with lazy loading
    func optimizedForList() -> some View {
        self
            .onDisappear {
                // Clean up when leaving view
                URLCache.shared.removeAllCachedResponses()
            }
    }
}

// MARK: - URLCache Configuration

func configureURLCache() {
    let diskCapacity = 100 * 1024 * 1024 // 100MB
    let memoryCapacity = 10 * 1024 * 1024 // 10MB
    let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: "http_cache")
    URLCache.shared = cache
}

// MARK: - Image Request Configuration

struct ImageRequestConfig {
    static let defaultURLSessionConfig: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = PerformanceConfig.networkTimeout
        config.timeoutIntervalForResource = 60
        config.urlCache = URLCache.shared
        config.requestCachePolicy = .returnCacheDataElseLoad
        return config
    }()
}
