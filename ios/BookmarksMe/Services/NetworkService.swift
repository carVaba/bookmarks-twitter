import Foundation

enum NetworkError: Error {
    case invalidURL
    case requestFailed
    case decodingError
}

class NetworkService {
    static let shared = NetworkService()

    // API URL from the HTML file
    private let apiUrlString = "https://script.google.com/macros/s/AKfycbz0IbRtw2CyBlZaerVK__ZYHbR3aeZd9BvwQREKReIVMxELrbVIbrxR5dn2EJHjj2CU/exec"

    private init() {}

    func fetchBookmarks() async throws -> [Bookmark] {
        guard let url = URL(string: apiUrlString) else {
            throw NetworkError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed
        }

        do {
            let bookmarks = try JSONDecoder().decode([Bookmark].self, from: data)
            return bookmarks
        } catch {
            print("Decoding error: \(error)")
            throw NetworkError.decodingError
        }
    }

    func incrementClick(id: String) async {
        let body: [String: Any] = ["action": "incrementClick", "id": id]
        await performPostRequest(body: body)
    }

    func deleteBookmark(id: String) async {
        let body: [String: Any] = ["action": "deleteBookmark", "id": id]
        await performPostRequest(body: body)
    }

    func updateCategory(id: String, category: String) async {
        let body: [String: Any] = ["action": "updateCategory", "id": id, "category": category]
        await performPostRequest(body: body)
    }

    private func performPostRequest(body: [String: Any]) async {
        guard let url = URL(string: apiUrlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // Using "text/plain" content-type for compatibility with Google Apps Script as seen in the HTML file's POST request
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData

            // Using a simple dataTask for 'no-cors' style fire-and-forget
            let _ = try await URLSession.shared.data(for: request)
        } catch {
            print("Error performing POST request: \(error)")
        }
    }
}
