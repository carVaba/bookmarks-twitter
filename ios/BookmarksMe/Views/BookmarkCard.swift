import SwiftUI

struct BookmarkCard: View {
    let bookmark: Bookmark
    let categories: [String]
    let onTap: () -> Void
    let onDelete: () -> Void
    let onUpdateCategory: (String) -> Void

    @State private var showingEditSheet = false

    // Apple HIG: CategoryColors
    private let categoryColors: [Color] = [.pink, .purple, .orange, .green, .blue, .purple, .red]

    private var categoryColor: Color {
        let cat = bookmark.category ?? "Unknown"
        let hash = abs(cat.hashValue)
        return categoryColors[hash % categoryColors.count]
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Category Badge
                Text(bookmark.category?.uppercased() ?? "UNKNOWN")
                    .font(.caption)
                    .fontWeight(.heavy)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(categoryColor.opacity(0.15))
                    .foregroundColor(categoryColor)
                    .clipShape(Capsule())

                // Thumbnail
                if let thumb = bookmark.thumbnail, let url = URL(string: thumb) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 160)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(16)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 160)
                                .clipped()
                                .cornerRadius(16)
                        case .failure:
                            EmptyView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                // Content
                Text(bookmark.content ?? "No content available")
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)

                Spacer()

                // Footer
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(bookmark.author ?? "Unknown")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(bookmark.clicks) clicks")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(UIColor.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .clipShape(Capsule())
                    }

                    if let parsedDate = bookmark.parsedDate {
                        Text(parsedDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .opacity(0.7)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(28)
            .shadow(color: Color.black.opacity(0.04), radius: 20, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: {
                showingEditSheet = true
            }) {
                Label("Move Category", systemImage: "folder")
            }

            Button(role: .destructive, action: onDelete) {
                Label("Delete Bookmark", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditCategorySheet(
                currentCategory: bookmark.category ?? "",
                availableCategories: categories,
                onSave: { newCategory in
                    onUpdateCategory(newCategory)
                }
            )
        }
    }
}

struct EditCategorySheet: View {
    @Environment(\.dismiss) var dismiss

    let currentCategory: String
    let availableCategories: [String]
    let onSave: (String) -> Void

    @State private var selectedCategory: String
    @State private var newCategoryName: String = ""
    @State private var isCreatingNew = false

    init(currentCategory: String, availableCategories: [String], onSave: @escaping (String) -> Void) {
        self.currentCategory = currentCategory
        self.availableCategories = availableCategories.filter { $0 != "All" }
        self.onSave = onSave
        self._selectedCategory = State(initialValue: currentCategory)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Existing Category")) {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(availableCategories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(.inline)
                    .onChange(of: selectedCategory) { _ in
                        isCreatingNew = false
                    }
                }

                Section(header: Text("Or Create New")) {
                    Toggle("Create New Category", isOn: $isCreatingNew)

                    if isCreatingNew {
                        TextField("New Category Name", text: $newCategoryName)
                    }
                }
            }
            .navigationTitle("Move Bookmark")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    let finalCategory = isCreatingNew && !newCategoryName.isEmpty ? newCategoryName : selectedCategory
                    onSave(finalCategory)
                    dismiss()
                }
                .fontWeight(.bold)
            )
        }
    }
}
