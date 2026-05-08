import Foundation

struct Bookmark: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var category: String?
    let author: String?
    let content: String?
    let url: String
    let thumbnail: String?
    let date: String?
    var clicks: Int

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case category = "Category"
        case author = "Author"
        case content = "Content"
        case url = "URL"
        case thumbnail = "Thumbnail"
        case date = "Date"
        case clicks = "Clicks"
    }

    init(id: String, category: String? = nil, author: String? = nil, content: String? = nil, url: String, thumbnail: String? = nil, date: String? = nil, clicks: Int = 0) {
        self.id = id
        self.category = category
        self.author = author
        self.content = content
        self.url = url
        self.thumbnail = thumbnail
        self.date = date
        self.clicks = clicks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // ID could be String or Int
        if let idInt = try? container.decodeIfPresent(Int.self, forKey: .id) {
            id = String(idInt)
        } else if let idString = try? container.decodeIfPresent(String.self, forKey: .id) {
            id = idString
        } else {
            id = UUID().uuidString
        }

        category = try container.decodeIfPresent(String.self, forKey: .category)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        url = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
        thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
        date = try container.decodeIfPresent(String.self, forKey: .date)

        // Clicks could be String or Int
        if let clicksInt = try? container.decodeIfPresent(Int.self, forKey: .clicks) {
            clicks = clicksInt
        } else if let clicksString = try? container.decodeIfPresent(String.self, forKey: .clicks), let parsed = Int(clicksString) {
            clicks = parsed
        } else {
            clicks = 0
        }
    }

    // Static formatters to avoid expensive initialization during sorting/filtering
    private static let isoFormatterFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let customFormatterT: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private static let customFormatterDateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    var parsedDate: Date? {
        guard let dateString = date, !dateString.isEmpty else { return nil }

        if let date = Bookmark.isoFormatterFractional.date(from: dateString) { return date }
        if let date = Bookmark.isoFormatter.date(from: dateString) { return date }
        if let date = Bookmark.customFormatterT.date(from: dateString) { return date }
        if let date = Bookmark.customFormatterDateOnly.date(from: dateString) { return date }

        return nil
    }
}
