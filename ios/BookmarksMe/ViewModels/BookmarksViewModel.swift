import Foundation
import SwiftUI

enum SortOption: String, CaseIterable, Identifiable {
    case newest = "Newest First"
    case oldest = "Oldest First"
    case clicksDesc = "Most Clicks"
    case clicksAsc = "Least Clicks"

    var id: String { self.rawValue }
}

@MainActor
@Observable
class BookmarksViewModel {
    var allBookmarks: [Bookmark] = []
    var filteredBookmarks: [Bookmark] = []

    var searchText: String = "" {
        didSet {
            // Cancel any previous debounce task
            searchTask?.cancel()
            searchTask = Task {
                // Debounce logic
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }
                self.applyFiltersAndSort()
            }
        }
    }
    private var searchTask: Task<Void, Never>?

    var selectedCategory: String = "All" {
        didSet {
            applyFiltersAndSort()
        }
    }
    var sortOption: SortOption = .newest {
        didSet {
            applyFiltersAndSort()
        }
    }

    var startDate: Date? {
        didSet {
            applyFiltersAndSort()
        }
    }
    var endDate: Date? {
        didSet {
            applyFiltersAndSort()
        }
    }

    var isLoading: Bool = false
    var errorMessage: String? = nil

    // Toast state
    var toastMessage: String? = nil
    var showToast: Bool = false
    @ObservationIgnored private var toastTimer: Timer?

    var categories: [String] {
        let cats = Set(allBookmarks.compactMap { $0.category }).sorted()
        return ["All"] + cats
    }

    var featuredBookmark: Bookmark? {
        guard !allBookmarks.isEmpty else { return nil }
        return allBookmarks.randomElement()
    }

    init() {}
   
    func fetchBookmarks() async {
        isLoading = true
        errorMessage = nil
        do {
            let bookmarks = try await NetworkService.shared.fetchBookmarks()
            self.allBookmarks = bookmarks
            self.applyFiltersAndSort()
            self.featuredBookmark = allBookmarks.randomElement()
        } catch {
            self.errorMessage = "Failed to load bookmarks. Please try again."
        }
        isLoading = false
    }

    // MARK: - Mutations

    func incrementClick(for id: String) {
        // Optimistic UI Update
        if let index = allBookmarks.firstIndex(where: { $0.id == id }) {
            allBookmarks[index].clicks += 1
            applyFiltersAndSort()
        }

        // Background API call
        Task {
            await NetworkService.shared.incrementClick(id: id)
        }
    }

    func deleteBookmark(id: String) {
        // Optimistic UI Update
        allBookmarks.removeAll { $0.id == id }
        applyFiltersAndSort()

        showToast(message: "Deleting in background...")

        // Background API call
        Task {
            await NetworkService.shared.deleteBookmark(id: id)
        }
    }

    func updateCategory(for id: String, newCategory: String) {
        // Optimistic UI Update
        if let index = allBookmarks.firstIndex(where: { $0.id == id }) {
            allBookmarks[index].category = newCategory
            applyFiltersAndSort()
        }

        showToast(message: "Moving to \(newCategory)...")

        // Background API call
        Task {
            await NetworkService.shared.updateCategory(id: id, category: newCategory)
        }
    }

    func showToast(message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }

        toastTimer?.invalidate()
        toastTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                withAnimation {
                    self?.showToast = false
                }
            }
        }
    }

    func applyFiltersAndSort() {
        var result = allBookmarks

        // 1. Search Text (Fuzzy-ish logic)
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { bookmark in
                let contentMatch = bookmark.content?.lowercased().contains(query) ?? false
                let authorMatch = bookmark.author?.lowercased().contains(query) ?? false
                let categoryMatch = bookmark.category?.lowercased().contains(query) ?? false
                return contentMatch || authorMatch || categoryMatch
            }
        }

        // 2. Category
        if selectedCategory != "All" {
            result = result.filter { $0.category == selectedCategory }
        }

        // 3. Date Range
        if let start = startDate {
            result = result.filter { bookmark in
                guard let bDate = bookmark.parsedDate else { return false }
                return bDate >= start
            }
        }

        if let end = endDate {
            // Adjust end date to the end of the day
            let calendar = Calendar.current
            if let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: end) {
                result = result.filter { bookmark in
                    guard let bDate = bookmark.parsedDate else { return false }
                    return bDate <= endOfDay
                }
            }
        }

        // 4. Sorting
        result.sort { a, b in
            let dateA = a.parsedDate ?? Date.distantPast
            let dateB = b.parsedDate ?? Date.distantPast
            let clicksA = a.clicks
            let clicksB = b.clicks

            switch sortOption {
            case .newest: return dateA > dateB
            case .oldest: return dateA < dateB
            case .clicksDesc: return clicksA > clicksB
            case .clicksAsc: return clicksA < clicksB
            }
        }

        self.filteredBookmarks = result
    }
}
