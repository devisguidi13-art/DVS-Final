import SwiftUI

private let accent = Color(red: 0.13, green: 0.87, blue: 0.43)
private let base = Color(red: 0.045, green: 0.055, blue: 0.052)
private let panel = Color(red: 0.115, green: 0.135, blue: 0.12)
private let muted = Color.white.opacity(0.60)

private enum MusicTab: String, CaseIterable {
    case home = "Home"
    case search = "Cerca"
    case discover = "Scopri"
    case library = "Libreria"
    case profile = "Profilo"

    var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .search: return "magnifyingglass"
        case .discover: return "sparkles"
        case .library: return "square.stack.fill"
        case .profile: return "person.crop.circle"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var player: PlaybackController
    @State private var tab: MusicTab = .home
    @State private var query = ""
    @State private var results: [MusicTrack] = []
    @State private var searching = false
    @State private var errorText: String?
    @State private var showPlayer = false
    @State private var showQueue = false
    @State private var showCreatePlaylist = false
    @State private var playlistName = ""
    @State private var playlistTarget: MusicTrack?
    @State private var showPlaylistOptions = false
    @State private var openedPlaylist: MusicPlaylist?
    @State private var discoveryLabel = ""
    private let catalog = CatalogService()
    private let genres = ["Trap italiana", "Indie", "Hip hop", "Pop", "R&B", "Rock", "Techno", "Reggaeton", "Lo-fi", "Chill"]

    var body: some View {
        VStack(spacing: 0) {
            header
            Group {
                switch tab {
                case .home: homePage
                case .search: searchPage
                case .discover: discoveryPage
                case .library: libraryPage
                case .profile: profilePage
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if player.current != nil { miniPlayer }
            tabBar
        }
        .background(base.ignoresSafeArea())
        .foregroundStyle(.white)
        .sheet(isPresented: $showPlayer) { playerSheet }
        .sheet(isPresented: $showQueue) { queueSheet }
        .sheet(item: $openedPlaylist) { playlist in playlistDetail(playlist) }
        .alert("Nuova playlist", isPresented: $showCreatePlaylist) {
            TextField("Nome della playlist", text: $playlistName)
            Button("Crea") {
                player.createPlaylist(named: playlistName)
                playlistName = ""
            }
            Button("Annulla", role: .cancel) { playlistName = "" }
        } message: { Text("Dai un nome alla tua raccolta") }
        .confirmationDialog("Aggiungi alla playlist", isPresented: $showPlaylistOptions) {
            ForEach(player.playlists) { playlist in
                Button(playlist.name) {
                    if let playlistTarget { player.addToPlaylist(playlistTarget, playlistID: playlist.id) }
                    playlistTarget = nil
                }
            }
            Button("Annulla", role: .cancel) { playlistTarget = nil }
        } message: { Text(player.playlists.isEmpty ? "Crea una playlist dalla Libreria" : "Scegli una playlist") }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(accent).frame(width: 38, height: 38)
                Text("D").font(.system(size: 23, weight: .black, design: .rounded)).foregroundStyle(.black)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text("DVS MUSIC").font(.system(size: 19, weight: .heavy, design: .rounded))
                Text("LA TUA MUSICA").font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(2).foregroundStyle(muted)
            }
            Spacer()
            Button { showQueue = true } label: {
                Image(systemName: "text.line.first.and.arrowtriangle.forward")
                    .font(.title3).foregroundStyle(.white)
                    .frame(width: 38, height: 38)
            }.accessibilityLabel("Apri coda")
            Button { tab = .profile } label: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 30)).foregroundStyle(accent)
            }.accessibilityLabel("Profilo")
        }
        .padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 12)
    }

    private var homePage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Il tuo sound.").font(.system(size: 36, weight: .black, design: .rounded))
                    Text("A modo tuo.").font(.system(size: 36, weight: .black, design: .rounded)).foregroundStyle(accent)
                    Text("Scopri, ascolta e lascia che la radio continui.")
                        .font(.footnote).foregroundStyle(muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(LinearGradient(colors: [Color(red: 0.07, green: 0.28, blue: 0.16), panel, base], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 22))

                HStack(spacing: 10) {
                    quickAction("Cerca musica", symbol: "magnifyingglass") { tab = .search }
                    quickAction("Scopri brani", symbol: "sparkles") { tab = .discover }
                }
                if !player.recentTracks.isEmpty {
                    sectionHeader("Ascoltati di recente", symbol: "clock.arrow.circlepath")
                    horizontalTracks(player.recentTracks)
                }
                if !player.favorites.isEmpty {
                    sectionHeader("I tuoi preferiti", symbol: "heart.fill")
                    horizontalTracks(player.favorites)
                }
                sectionHeader("La tua radio", symbol: "dot.radiowaves.left.and.right")
                VStack(alignment: .leading, spacing: 12) {
                    Label("Coda intelligente", systemImage: "waveform.path")
                        .font(.headline).foregroundStyle(accent)
                    Text("Riproduci un brano e DVS Music cercherà automaticamente musica affine usando artisti, stili e suggerimenti disponibili.")
                        .font(.subheadline).foregroundStyle(muted)
                    Toggle("Attiva la radio", isOn: Binding(get: { player.autoRadio }, set: { player.autoRadio = $0 }))
                        .tint(accent)
                    Toggle("Suggerimenti intelligenti", isOn: Binding(get: { player.smartRadio }, set: { player.setSmartRadio($0) }))
                        .tint(accent)
                }
                .padding(18).background(panel, in: RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, 18).padding(.bottom, 25)
        }
    }

    private func quickAction(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: symbol).foregroundStyle(accent)
                Text(title).font(.subheadline.weight(.semibold))
                Spacer(minLength: 0)
            }
            .padding(14).frame(maxWidth: .infinity)
            .background(panel, in: RoundedRectangle(cornerRadius: 15))
        }.buttonStyle(.plain)
    }

    private var searchPage: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cosa vuoi ascoltare?").font(.system(size: 25, weight: .bold)).padding(.horizontal, 18)
            searchBox
            if let errorText {
                Text(errorText).font(.footnote).foregroundStyle(.orange).padding(.horizontal, 18)
            }
            if searching { ProgressView("Ricerca in corso...").tint(accent).frame(maxWidth: .infinity) }
            if results.isEmpty && !searching {
                emptyState("magnifyingglass", title: "Trova il tuo prossimo brano", subtitle: "Cerca un titolo o un artista. Puoi anche incollare un link YouTube.")
            } else { trackList(results) }
        }
    }

    private var searchBox: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(accent)
            TextField("Artista, canzone o link", text: $query)
                .tint(accent).textInputAutocapitalization(.never).autocorrectionDisabled()
                .submitLabel(.search).onSubmit { Task { await search() } }
            if searching { ProgressView().tint(accent) }
            Button { Task { await search() } } label: {
                Image(systemName: "arrow.right.circle.fill").font(.title2).foregroundStyle(accent)
            }.accessibilityLabel("Avvia ricerca")
        }
        .padding(14).background(panel, in: RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal, 18)
    }

    private var discoveryPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Discovery").font(.system(size: 31, weight: .black))
                Text("Un nuovo mood, un nuovo ascolto.").foregroundStyle(muted)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(genres.indices, id: \.self) { index in
                        Button {
                            discoveryLabel = genres[index]
                            query = genres[index] + " music"
                            tab = .search
                            Task { await search() }
                        } label: {
                            VStack(alignment: .leading, spacing: 22) {
                                Image(systemName: ["bolt.fill", "cloud.fill", "waveform", "music.note", "moon.stars.fill", "guitars.fill", "slider.horizontal.3", "flame.fill", "headphones", "sparkles"][index])
                                    .font(.title).foregroundStyle(.white.opacity(0.85))
                                Text(genres[index]).font(.headline).multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, minHeight: 105, alignment: .leading)
                            .padding(15)
                            .background(genreColor(index), in: RoundedRectangle(cornerRadius: 18))
                        }.buttonStyle(.plain)
                    }
                }
                if !discoveryLabel.isEmpty {
                    Text("Ultimo mood: \(discoveryLabel)").font(.caption).foregroundStyle(muted)
                }
            }.padding(.horizontal, 18).padding(.bottom, 24)
        }
    }

    private func genreColor(_ index: Int) -> Color {
        let palette: [Color] = [
            Color(red: 0.40, green: 0.13, blue: 0.22), Color(red: 0.20, green: 0.31, blue: 0.40),
            Color(red: 0.28, green: 0.20, blue: 0.49), Color(red: 0.51, green: 0.21, blue: 0.25),
            Color(red: 0.23, green: 0.19, blue: 0.36), Color(red: 0.39, green: 0.27, blue: 0.17),
            Color(red: 0.10, green: 0.35, blue: 0.31), Color(red: 0.50, green: 0.21, blue: 0.13),
            Color(red: 0.16, green: 0.36, blue: 0.42), Color(red: 0.23, green: 0.38, blue: 0.25)
        ]
        return palette[index % palette.count]
    }

    private var libraryPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("La tua libreria").font(.system(size: 28, weight: .black))
                    Spacer()
                    Button { showCreatePlaylist = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title).foregroundStyle(accent)
                    }.accessibilityLabel("Crea playlist")
                }
                Button {
                    if let first = player.favorites.first { player.playSelection(player.favorites, selected: first) }
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 11).fill(LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                            Image(systemName: "heart.fill").font(.title).foregroundStyle(.white)
                        }.frame(width: 62, height: 62)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Brani che ti piacciono").font(.headline)
                            Text("\(player.favorites.count) brani").font(.caption).foregroundStyle(muted)
                        }
                        Spacer()
                        Image(systemName: "play.circle.fill").font(.title2).foregroundStyle(accent)
                    }
                }.buttonStyle(.plain)
                HStack {
                    sectionHeader("Le tue playlist", symbol: "square.stack.fill")
                    Spacer()
                    Text("\(player.playlists.count)").foregroundStyle(muted)
                }
                if player.playlists.isEmpty {
                    Text("Nessuna playlist. Tocca + per crearne una.")
                        .font(.footnote).foregroundStyle(muted)
                }
                ForEach(player.playlists) { playlist in
                    HStack(spacing: 14) {
                        Button { openedPlaylist = playlist } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12).fill(panel)
                                    Image(systemName: "music.note.list").foregroundStyle(accent)
                                }.frame(width: 54, height: 54)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(playlist.name).font(.headline)
                                    Text("\(playlist.tracks.count) brani").font(.caption).foregroundStyle(muted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(muted)
                            }
                        }.buttonStyle(.plain)
                        Button { player.deletePlaylist(playlist.id) } label: {
                            Image(systemName: "trash").foregroundStyle(muted)
                        }.accessibilityLabel("Elimina playlist")
                    }
                }
                if !player.favorites.isEmpty {
                    sectionHeader("Tutti i preferiti", symbol: "heart")
                    ForEach(player.favorites) { track in trackRow(track) { player.playSelection(player.favorites, selected: track) } }
                }
            }.padding(.horizontal, 18).padding(.bottom, 24)
        }
    }

    private var profilePage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle().fill(LinearGradient(colors: [accent, .green, .black], startPoint: .topLeading, endPoint: .bottomTrailing))
                        Text("DVS").font(.title2.weight(.black)).foregroundStyle(.black)
                    }.frame(width: 83, height: 83)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Il mio profilo").font(.system(size: 27, weight: .bold))
                        Text("DVS Music · Privato").font(.subheadline).foregroundStyle(muted)
                    }
                }
                HStack(spacing: 12) {
                    statCard("\(player.favorites.count)", "Preferiti")
                    statCard("\(player.playlists.count)", "Playlist")
                    statCard("\(player.recentTracks.count)", "Recenti")
                }
                sectionHeader("Impostazioni di ascolto", symbol: "slider.horizontal.3")
                VStack(spacing: 17) {
                    Toggle("Radio infinita", isOn: Binding(get: { player.autoRadio }, set: { player.autoRadio = $0 }))
                    Divider().overlay(Color.white.opacity(0.1))
                    Toggle("Coda intelligente", isOn: Binding(get: { player.smartRadio }, set: { player.setSmartRadio($0) }))
                    Divider().overlay(Color.white.opacity(0.1))
                    Toggle("Riproduzione casuale", isOn: $player.shuffle)
                }.tint(accent).padding(17).background(panel, in: RoundedRectangle(cornerRadius: 18))
                sectionHeader("Informazioni", symbol: "info.circle")
                Text("DVS Music 0.6 · iPhone\nPlayer audio nativo e controlli dalla schermata di blocco. Catalogo sperimentale: risultati e flussi possono essere indisponibili a causa delle sorgenti esterne.")
                    .font(.footnote).foregroundStyle(muted).lineSpacing(5)
            }.padding(.horizontal, 18).padding(.bottom, 24)
        }
    }

    private func statCard(_ value: String, _ caption: String) -> some View {
        VStack(spacing: 5) {
            Text(value).font(.title2.weight(.bold)).foregroundStyle(accent)
            Text(caption).font(.caption2).foregroundStyle(muted)
        }.frame(maxWidth: .infinity).padding(14).background(panel, in: RoundedRectangle(cornerRadius: 14))
    }

    private func sectionHeader(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol).font(.headline).foregroundStyle(.white)
    }

    private func horizontalTracks(_ tracks: [MusicTrack]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 13) {
                ForEach(Array(tracks.prefix(12))) { track in
                    Button { player.playSelection(tracks, selected: track) } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Artwork(track: track, size: 128)
                            Text(track.title).font(.subheadline.weight(.semibold)).lineLimit(2)
                            Text(track.artist).font(.caption).foregroundStyle(muted).lineLimit(1)
                        }.frame(width: 128, alignment: .leading)
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private func trackList(_ tracks: [MusicTrack]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(tracks) { track in
                    trackRow(track) { player.playSelection(tracks, selected: track) }
                }
            }.padding(.horizontal, 18).padding(.bottom, 20)
        }
    }

    private func trackRow(_ track: MusicTrack, action: @escaping () -> Void) -> some View {
        HStack(spacing: 11) {
            Button(action: action) {
                HStack(spacing: 11) {
                    Artwork(track: track, size: 50)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.title).font(.subheadline.weight(.semibold))
                            .foregroundStyle(player.current?.id == track.id ? accent : .white).lineLimit(1)
                        Text(track.artist).font(.caption).foregroundStyle(muted).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
            }.buttonStyle(.plain)
            Button { player.toggleFavorite(track) } label: {
                Image(systemName: player.isFavorite(track) ? "heart.fill" : "heart")
                    .foregroundStyle(player.isFavorite(track) ? accent : muted)
            }.accessibilityLabel("Preferito")
            Menu {
                Button(action: action) { Label("Riproduci", systemImage: "play.fill") }
                Button { player.append(track) } label: { Label("Aggiungi alla coda", systemImage: "text.badge.plus") }
                Button {
                    playlistTarget = track
                    showPlaylistOptions = true
                } label: { Label("Aggiungi a playlist", systemImage: "square.stack.badge.plus") }
            } label: {
                Image(systemName: "ellipsis").font(.title3).foregroundStyle(muted)
                    .padding(.leading, 4)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var miniPlayer: some View {
        VStack(spacing: 0) {
            if player.duration > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Color.white.opacity(0.1)
                        accent.frame(width: geometry.size.width * min(1, max(0, player.elapsed / player.duration)))
                    }
                }.frame(height: 2)
            }
            HStack(spacing: 10) {
                if let track = player.current {
                    Artwork(track: track, size: 43)
                    Button { showPlayer = true } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(track.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                            Text(track.artist).font(.caption).foregroundStyle(muted).lineLimit(1)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }.buttonStyle(.plain)
                }
                if player.preparing { ProgressView().tint(accent) }
                Button { player.togglePlayback() } label: {
                    Image(systemName: player.playing ? "pause.fill" : "play.fill")
                        .font(.title3).foregroundStyle(.white).frame(width: 35, height: 40)
                }
                Button { player.next() } label: {
                    Image(systemName: "forward.end.fill").font(.title3).foregroundStyle(.white)
                }
            }.padding(9)
        }
        .background(Color(red: 0.12, green: 0.21, blue: 0.16), in: RoundedRectangle(cornerRadius: 13))
        .padding(.horizontal, 9).padding(.bottom, 4)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(MusicTab.allCases, id: \.self) { option in
                Button { tab = option } label: {
                    VStack(spacing: 4) {
                        Image(systemName: option.symbol).font(.system(size: 20))
                        Text(option.rawValue).font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(tab == option ? accent : muted)
                    .frame(maxWidth: .infinity).frame(height: 52)
                }.buttonStyle(.plain)
            }
        }
        .background(base)
    }

    private var playerSheet: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Spacer(minLength: 10)
                if let track = player.current {
                    GeometryReader { geometry in
                        Artwork(track: track, size: min(geometry.size.width, geometry.size.height))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }.frame(height: 275)
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(track.title).font(.title2.weight(.bold)).lineLimit(2)
                                Text(track.artist).foregroundStyle(muted)
                            }
                            Spacer()
                            Button { player.toggleFavorite(track) } label: {
                                Image(systemName: player.isFavorite(track) ? "heart.fill" : "heart")
                                    .font(.title2).foregroundStyle(accent)
                            }
                        }
                    }
                }
                if let error = player.errorMessage {
                    Text(error).font(.footnote).foregroundStyle(.orange)
                }
                VStack(spacing: 5) {
                    if player.duration > 1 {
                        Slider(value: Binding(get: { min(player.elapsed, player.duration) }, set: { player.seek(to: $0) }),
                               in: 0...max(player.duration, 1)).tint(accent)
                    }
                    HStack {
                        Text(timeLabel(player.elapsed))
                        Spacer()
                        Text(timeLabel(player.duration))
                    }.font(.caption.monospacedDigit()).foregroundStyle(muted)
                }
                HStack(spacing: 27) {
                    Button { player.shuffle.toggle() } label: {
                        Image(systemName: "shuffle").foregroundStyle(player.shuffle ? accent : muted)
                    }
                    Button { player.previous() } label: { Image(systemName: "backward.end.fill") }
                    Button { player.togglePlayback() } label: {
                        Image(systemName: player.playing ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 66)).foregroundStyle(accent)
                    }
                    Button { player.next() } label: { Image(systemName: "forward.end.fill") }
                    Button { player.cycleRepeat() } label: {
                        Image(systemName: "repeat").foregroundStyle(player.repeatSetting == .all ? accent : muted)
                    }
                }.font(.title2)
                HStack {
                    Label(player.autoRadio ? "Radio attiva" : "Radio spenta", systemImage: "dot.radiowaves.left.and.right")
                        .font(.footnote).foregroundStyle(muted)
                    Spacer()
                    Button { showPlayer = false; showQueue = true } label: {
                        Label("Coda", systemImage: "list.bullet").foregroundStyle(accent)
                    }
                }
                Spacer(minLength: 4)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LinearGradient(colors: [Color(red: 0.08, green: 0.29, blue: 0.18), base], startPoint: .top, endPoint: .center).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Chiudi") { showPlayer = false }.foregroundStyle(accent) }
            }
        }.preferredColorScheme(.dark)
    }

    private var queueSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "sparkles").foregroundStyle(accent)
                    Text("Coda intelligente").font(.headline)
                    Spacer()
                    Toggle("Radio", isOn: Binding(get: { player.autoRadio }, set: { player.autoRadio = $0 }))
                        .labelsHidden().tint(accent)
                }.padding(.horizontal, 18)
                Text("Usa le frecce per cambiare ordine; rimuovi i brani con il cestino. La riproduzione in corso non viene interrotta.")
                    .font(.caption).foregroundStyle(muted).padding(.horizontal, 18)
                if player.queue.isEmpty {
                    emptyState("music.note.list", title: "Coda vuota", subtitle: "Riproduci un brano per iniziare.")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(player.queue.indices, id: \.self) { index in
                                let track = player.queue[index]
                                HStack(spacing: 10) {
                                    Artwork(track: track, size: 48)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(track.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                                            .foregroundStyle(index == player.currentIndex ? accent : .white)
                                        Text(index == player.currentIndex ? "In riproduzione" : track.artist)
                                            .font(.caption).foregroundStyle(muted).lineLimit(1)
                                    }
                                    Spacer(minLength: 0)
                                    if index > player.currentIndex {
                                        Button { player.moveUpcoming(at: index, by: -1) } label: {
                                            Image(systemName: "chevron.up").foregroundStyle(accent)
                                        }.disabled(index == player.currentIndex + 1)
                                        Button { player.moveUpcoming(at: index, by: 1) } label: {
                                            Image(systemName: "chevron.down").foregroundStyle(accent)
                                        }.disabled(index == player.queue.count - 1)
                                        Button { player.removeUpcoming(at: index) } label: {
                                            Image(systemName: "trash").foregroundStyle(muted)
                                        }
                                    } else {
                                        Image(systemName: "waveform").foregroundStyle(accent)
                                    }
                                }.padding(.vertical, 8)
                            }
                        }.padding(.horizontal, 18)
                    }
                }
            }
            .padding(.top, 15).frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(base.ignoresSafeArea())
            .navigationTitle("Prossimi brani")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Fine") { showQueue = false }.foregroundStyle(accent) }
            }
        }.preferredColorScheme(.dark)
    }

    private func playlistDetail(_ playlist: MusicPlaylist) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(playlist.name).font(.largeTitle.weight(.bold))
                    Text("\(playlist.tracks.count) brani").foregroundStyle(muted)
                    if let first = playlist.tracks.first {
                        Button { player.playSelection(playlist.tracks, selected: first) } label: {
                            Label("Riproduci tutti", systemImage: "play.fill")
                                .font(.headline).foregroundStyle(.black).padding(12)
                                .frame(maxWidth: .infinity)
                                .background(accent, in: Capsule())
                        }
                    }
                    ForEach(playlist.tracks) { track in
                        HStack {
                            trackRow(track) { player.playSelection(playlist.tracks, selected: track) }
                            Button { player.removeFromPlaylist(track, playlistID: playlist.id) } label: {
                                Image(systemName: "minus.circle").foregroundStyle(muted)
                            }
                        }
                    }
                }.padding(18)
            }
            .background(base.ignoresSafeArea())
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Fine") { openedPlaylist = nil }.foregroundStyle(accent) } }
        }.preferredColorScheme(.dark)
    }

    private func emptyState(_ symbol: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: symbol).font(.system(size: 46)).foregroundStyle(accent)
            Text(title).font(.title3.weight(.bold))
            Text(subtitle).font(.footnote).foregroundStyle(muted).multilineTextAlignment(.center)
            Spacer()
        }.frame(maxWidth: .infinity).padding(28)
    }

    private func timeLabel(_ number: Double) -> String {
        let seconds = Int(number.isFinite ? max(number, 0) : 0)
        return "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }

    private func search() async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        searching = true
        errorText = nil
        do { results = try await catalog.search(text) }
        catch { errorText = "Ricerca non disponibile: \(error.localizedDescription)"; results = [] }
        searching = false
    }
}

private struct Artwork: View {
    let track: MusicTrack
    let size: CGFloat
    var body: some View {
        AsyncImage(url: track.artworkURL) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            ZStack {
                Color(red: 0.10, green: 0.29, blue: 0.17)
                Image(systemName: "waveform").font(.title3).foregroundStyle(accent)
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
