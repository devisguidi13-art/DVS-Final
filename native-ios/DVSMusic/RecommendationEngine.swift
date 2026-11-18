import Foundation

/// Lightweight, explainable personal radio. The public catalog does not provide Spotify-like
/// listening embeddings: suggestions are ranked with available title/artist metadata.
struct RecommendationEngine {
    private let catalog = CatalogService()

    private let genreTerms: [String: [String]] = [
        "trap": ["trap", "drill", "rap", "hip hop", "hiphop", "freestyle", "migos", "future", "shiva", "sfera", "capo plaza"],
        "indie": ["indie", "alternative", "lofi", "bedroom", "bresh", "psicologi", "olly"],
        "pop": ["pop", "radio", "hits", "dance pop"],
        "rock": ["rock", "punk", "metal", "grunge"],
        "electronic": ["techno", "house", "edm", "electronic", "dance"],
        "rnb": ["r&b", "rnb", "soul", "frank ocean", "the weeknd"],
        "latin": ["reggaeton", "latin", "bachata", "salsa", "urbano"]
    ]

    func recommendations(near track: MusicTrack, excluding excluded: Set<String>) async -> [MusicTrack] {
        var candidates = await catalog.suggested(near: track)
        if candidates.count < 6 {
            // A second discovery source when recommendation endpoints return too few items.
            let extra = (try? await catalog.search("\(track.artist) music")) ?? []
            candidates.append(contentsOf: extra)
        }
        let anchorGenre = genres(for: track)
        let anchorArtist = clean(track.artist)
        let anchorWords = Set(tokens(track.title))
        var seen = excluded.union([track.id])
        let filtered = candidates.filter { candidate in
            guard !seen.contains(candidate.id), candidate.id != track.id else { return false }
            seen.insert(candidate.id)
            return candidate.duration == 0 || (candidate.duration >= 70 && candidate.duration <= 660)
        }
        return filtered.sorted { score($0) > score($1) }.prefix(16).map { $0 }

        func score(_ candidate: MusicTrack) -> Int {
            let artist = clean(candidate.artist)
            let title = clean(candidate.title)
            var points = 0
            if !anchorArtist.isEmpty && anchorArtist != "youtube" && artist == anchorArtist { points += 48 }
            else if !anchorArtist.isEmpty && anchorArtist != "youtube" &&
                        (artist.contains(anchorArtist) || title.contains(anchorArtist)) { points += 28 }
            points += genres(for: candidate).intersection(anchorGenre).count * 22
            points += Set(tokens(candidate.title)).intersection(anchorWords).count * 3
            if candidate.duration >= 120 && candidate.duration <= 360 { points += 7 }
            if title.contains("official audio") || title.contains("audio") { points += 3 }
            if title.contains("reaction") || title.contains("interview") || title.contains("tutorial") || title.contains("podcast") { points -= 60 }
            if title.contains("1 hour") || title.contains("extended") { points -= 15 }
            return points
        }
    }

    private func genres(for track: MusicTrack) -> Set<String> {
        let content = clean(track.title + " " + track.artist)
        return Set(genreTerms.compactMap { genre, terms in
            terms.contains(where: { content.contains($0) }) ? genre : nil
        })
    }

    private func clean(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).lowercased()
    }

    private func tokens(_ text: String) -> [String] {
        clean(text).components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 3 && !["official", "video", "music", "audio"].contains($0) }
    }
}
