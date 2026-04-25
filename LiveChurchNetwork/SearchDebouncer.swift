import Combine
import Foundation

class SearchDebouncer: NSObject, ObservableObject {
    @Published var debouncedSearchText = ""
    @Published var isSearching = false

    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    private let debounceTime: TimeInterval

    init(debounceTime: TimeInterval = PerformanceConfig.searchDebounceTime) {
        self.debounceTime = debounceTime
        super.init()
    }

    func search(_ text: String, onSearch: @escaping (String) async -> Void) {
        // Cancel previous task
        searchTask?.cancel()

        guard !text.isEmpty else {
            debouncedSearchText = ""
            return
        }

        isSearching = true

        searchTask = Task {
            // Wait for debounce period
            try? await Task.sleep(nanoseconds: UInt64(debounceTime * 1_000_000_000))

            // Check if task was cancelled
            if Task.isCancelled {
                return
            }

            // Update debounced text and perform search
            await MainActor.run {
                self.debouncedSearchText = text
            }

            await onSearch(text)

            await MainActor.run {
                self.isSearching = false
            }
        }
    }

    func cancel() {
        searchTask?.cancel()
        isSearching = false
        debouncedSearchText = ""
    }
}

// MARK: - Search Helper for ViewModel

extension DiscoverViewModel {
    func performDebouncedSearch(_ query: String, debouncer: SearchDebouncer) {
        debouncer.search(query) { _ in
            Task {
                await self.reloadChurchesWithFilters()
            }
        }
    }
}
