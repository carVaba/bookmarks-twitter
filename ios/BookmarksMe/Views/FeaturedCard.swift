import SwiftUI

struct FeaturedCard: View {
    let bookmark: Bookmark
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                Text(bookmark.author ?? "Unknown")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .foregroundColor(.primary)

                Text(bookmark.content ?? "No content")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                // Liquid Glass Aesthetic
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color(UIColor.systemBackground).opacity(0.4))
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(Material.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
