import SwiftUI

struct CategoryTabs: View {
    let categories: [String]
    @Binding var selectedCategory: String

    // Apple HIG: CategoryColors logic inspired by web colors
    private let categoryColors: [Color] = [.pink, .purple, .orange, .green, .blue, .purple, .red]

    private func colorForCategory(_ category: String) -> Color {
        if category == "All" { return .primary }
        let hash = abs(category.hashValue)
        return categoryColors[hash % categoryColors.count]
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        withAnimation {
                            selectedCategory = category
                        }
                    }) {
                        Text(category)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                selectedCategory == category ?
                                (category == "All" ? Color.primary : colorForCategory(category)) :
                                Color(UIColor.secondarySystemGroupedBackground)
                            )
                            .foregroundColor(
                                selectedCategory == category ?
                                Color(UIColor.systemBackground) :
                                .primary
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(
                                        selectedCategory == category ?
                                        Color.clear :
                                        Color.gray.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}
