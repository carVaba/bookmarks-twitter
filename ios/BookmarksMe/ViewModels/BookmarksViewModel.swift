import Foundation
import Combine
import SwiftUI

enum SortOption: String, CaseIterable, Identifiable {
    case newest = "Newest First"
    case oldest = "Oldest First"
    case clicksDesc = "Most Clicks"
    case clicksAsc = "Least Clicks"

    var id: String { self.rawValue }
}

@MainActor
class BookmarksViewModel: ObservableObject {
    @Published var allBookmarks: [Bookmark] = []
    @Published var filteredBookmarks: [Bookmark] = []

    @Published var searchText: String = ""
    @Published var selectedCategory: String = "All"
    @Published var sortOption: SortOption = .newest

    @Published var startDate: Date?
    @Published var endDate: Date?

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // Toast state
    @Published var toastMessage: String? = nil
    @Published var showToast: Bool = false
    private var toastTimer: Timer?

    var categories: [String] {
        let cats = Set(allBookmarks.compactMap { $0.category }).sorted()
        return ["All"] + cats
    }

    var featuredBookmark: Bookmark? {
        guard !allBookmarks.isEmpty else { return nil }
        return allBookmarks.randomElement()
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }

    func fetchBookmarks() async {
        isLoading = true
        errorMessage = nil
        do {
            let bookmarks = try await NetworkService.shared.fetchBookmarks()
            self.allBookmarks = bookmarks
            self.applyFiltersAndSort()
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

    private func setupBindings() {
        $searchText
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)

        $selectedCategory
            .dropFirst()
            .sink { [weak self] _ in
                // Need a small delay to let the state update before filtering
                DispatchQueue.main.async {
                    self?.applyFiltersAndSort()
                }
            }
            .store(in: &cancellables)

        $sortOption
            .dropFirst()
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.applyFiltersAndSort()
                }
            }
            .store(in: &cancellables)

        $startDate
            .dropFirst()
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.applyFiltersAndSort()
                }
            }
            .store(in: &cancellables)

        $endDate
            .dropFirst()
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.applyFiltersAndSort()
                }
            }
            .store(in: &cancellables)
    }
}
