import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = BookmarksViewModel()
    @State private var showingFilters = false
    @State private var selectedURL: URL?

    // Grid configuration: responsive sizing based on container width
    let columns = [
        GridItem(.adaptive(minimum: 320, maximum: .infinity), spacing: 24)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Featured Card (Rediscover)
                        if let featured = viewModel.featuredBookmark {
                            VStack(alignment: .leading) {
                                Text("Rediscover")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .padding(.horizontal)

                                FeaturedCard(bookmark: featured) {
                                    handleTap(for: featured)
                                }
                                .padding(.horizontal)
                            }
                            .padding(.top, 10)
                        }

                        // Category Tabs
                        if !viewModel.categories.isEmpty {
                            CategoryTabs(
                                categories: viewModel.categories,
                                selectedCategory: $viewModel.selectedCategory
                            )
                        }

                        // Loading State
                        if viewModel.isLoading && viewModel.allBookmarks.isEmpty {
                            ProgressView("Syncing Data...")
                                .padding(50)
                        } else if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                            Button("Retry") {
                                Task { await viewModel.fetchBookmarks() }
                            }
                            .buttonStyle(.bordered)
                        } else {
                            // Grid
                            LazyVGrid(columns: columns, spacing: 24) {
                                ForEach(viewModel.filteredBookmarks) { bookmark in
                                    BookmarkCard(
                                        bookmark: bookmark,
                                        categories: viewModel.categories,
                                        onTap: {
                                            handleTap(for: bookmark)
                                        },
                                        onDelete: {
                                            viewModel.deleteBookmark(id: bookmark.id)
                                        },
                                        onUpdateCategory: { newCat in
                                            viewModel.updateCategory(for: bookmark.id, newCategory: newCat)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 40)
                        }
                    }
                }
                .refreshable {
                    await viewModel.fetchBookmarks()
                }
                .searchable(text: $viewModel.searchText, prompt: "Search ideas, authors...")
                .navigationTitle("Bookmarks")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingFilters.toggle() }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.title3)
                        }
                    }
                }
                .sheet(isPresented: $showingFilters) {
                    FilterSheet(
                        sortOption: $viewModel.sortOption,
                        startDate: $viewModel.startDate,
                        endDate: $viewModel.endDate
                    )
                }
                .sheet(item: Binding<URLWrapper>(
                    get: { selectedURL.map { URLWrapper(url: $0) } },
                    set: { selectedURL = $0?.url }
                )) { wrapper in
                    SafariView(url: wrapper.url)
                        .ignoresSafeArea()
                }

                // Toast overlay
                if viewModel.showToast, let message = viewModel.toastMessage {
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            ProgressView()
                                .tint(.primary)
                            Text(message)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color(UIColor.systemBackground))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .ignoresSafeArea(.keyboard)
                }
            }
        }
        .navigationViewStyle(.stack) // Better for iPad
        .task {
            if viewModel.allBookmarks.isEmpty {
                await viewModel.fetchBookmarks()
            }
        }
    }

    private func handleTap(for bookmark: Bookmark) {
        if let url = URL(string: bookmark.url) {
            selectedURL = url
            viewModel.incrementClick(for: bookmark.id)
        }
    }
}

// Helper for sheet presentation
struct URLWrapper: Identifiable {
    let id = UUID()
    let url: URL
}

struct FilterSheet: View {
    @Environment(\.dismiss) var dismiss

    @Binding var sortOption: SortOption
    @Binding var startDate: Date?
    @Binding var endDate: Date?

    @State private var localStart: Date = Date()
    @State private var localEnd: Date = Date()
    @State private var useStartDate = false
    @State private var useEndDate = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sort")) {
                    Picker("Sort By", selection: $sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }

                Section(header: Text("Filter by Date")) {
                    Toggle("Use Start Date", isOn: $useStartDate)
                    if useStartDate {
                        DatePicker("Start Date", selection: $localStart, displayedComponents: .date)
                    }

                    Toggle("Use End Date", isOn: $useEndDate)
                    if useEndDate {
                        DatePicker("End Date", selection: $localEnd, displayedComponents: .date)
                    }
                }

                Section {
                    Button("Clear Filters") {
                        useStartDate = false
                        useEndDate = false
                        sortOption = .newest
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filters")
            .navigationBarItems(trailing: Button("Done") {
                startDate = useStartDate ? localStart : nil
                endDate = useEndDate ? localEnd : nil
                dismiss()
            }.fontWeight(.bold))
            .onAppear {
                if let start = startDate {
                    localStart = start
                    useStartDate = true
                }
                if let end = endDate {
                    localEnd = end
                    useEndDate = true
                }
            }
        }
    }
}
