import Foundation

/// Public, unauthenticated Invidious instances; no personal backend is required.
/// They may rate-limit, change or stop operating. Never send account credentials.
struct CatalogService {
    private let instances = [
        "https://inv.nadeko.net",
        "https://invidious.nerdvpn.de",
        "https://yt.chocolatemoo53.com",
        "https://invidious.tiekoetter.com"
    ]

    func search(_ text: String) async throws -> [MusicTrack] {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        if let videoID = Self.videoID(from: query) {
            return [MusicTrack(id: videoID, title: "Brano YouTube", artist: "YouTube", duration: 0)]
        }
        var lastError: Error?
        for instance in instances {
            do {
                var components = URLComponents(string: instance + "/api/v1/search")!
                components.queryItems = [
                    URLQueryItem(name: "q", value: query),
                    URLQueryItem(name: "type", value: "video"),
                    URLQueryItem(name: "region", value: "IT")
                ]
                let videos: [InvidiousVideo] = try await fetch(components.url!)
                let tracks = unique(videos.compactMap { $0.asTrack() })
                if !tracks.isEmpty { return tracks }
            } catch { lastError = error }
        }
        throw lastError ?? CatalogError.noResults
    }

    // Direct links also work when a public search endpoint is unavailable.
    static func videoID(from input: String) -> String? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if isVideoID(text) { return text }
        guard let url = URLComponents(string: text),
              let host = url.host?.lowercased() else { return nil }
        let pathParts = url.path.split(separator: "/").map(String.init)
        let candidate: String?
        if host == "youtu.be" || host == "www.youtu.be" {
            candidate = pathParts.first
        } else if ["youtube.com", "www.youtube.com", "m.youtube.com", "music.youtube.com", "youtube-nocookie.com", "www.youtube-nocookie.com"].contains(host) {
            if url.path == "/watch" {
                candidate = url.queryItems?.first(where: { $0.name == "v" })?.value
            } else if pathParts.count >= 2, ["shorts", "embed", "live"].contains(pathParts[0]) {
                candidate = pathParts[1]
            } else {
                candidate = nil
            }
        } else {
            candidate = nil
        }
        return candidate.flatMap { isVideoID($0) ? $0 : nil }
    }

    private static func isVideoID(_ text: String) -> Bool {
        text.count == 11 && text.unicodeScalars.allSatisfy { scalar in
            ("A"..."Z").contains(String(scalar)) || ("a"..."z").contains(String(scalar)) ||
            ("0"..."9").contains(String(scalar)) || scalar == "-" || scalar == "_"
        }
    }

    func suggested(near track: MusicTrack) async -> [MusicTrack] {
        for instance in instances {
            do {
                let url = URL(string: "\(instance)/api/v1/videos/\(track.id)")!
                let detail: InvidiousVideoDetail = try await fetch(url)
                let results = unique((detail.recommendedVideos ?? []).compactMap { $0.asTrack() })
                if !results.isEmpty { return results }
            } catch { continue }
        }
        return []
    }

    private func fetch<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw CatalogError.serviceUnavailable
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func unique(_ input: [MusicTrack]) -> [MusicTrack] {
        var ids = Set<String>()
        return input.filter { ids.insert($0.id).inserted }
    }
}

enum CatalogError: LocalizedError {
    case noResults, serviceUnavailable
    var errorDescription: String? {
        switch self {
        case .noResults: return "Nessun brano trovato. Prova con artista e titolo."
        case .serviceUnavailable: return "Catalogo temporaneamente non disponibile. Le istanze pubbliche possono essere bloccate."
        }
    }
}
