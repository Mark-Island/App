/**
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import FairApp
import Foundation

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
@main public struct AppScene : FairApp.FairScene {
    @ObservedObject public var appEnv: FairManager = FairManager()
    public var settings : some View {
        AppSettingsView()
            .environmentObject(appEnv)
    }
    public init() { }
    public static func main() throws { try Self.launch() }
}

public extension Bundle {
    /// The URL for the App's resource bundle
    static var appBundleURL: URL! {
        Bundle.module.url(forResource: "Bundle", withExtension: nil)
    }
}

// Everything above this line must remain unmodified.

// Code your app in the AppScene and ContentView below.

import FairCore
import SwiftUI

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public extension AppScene {
    /// The body of your scene must exist in an extension of `AppScene`
    var body: some Scene {
        WindowGroup {
            NavigationRootView()
                .environmentObject(appEnv)
                .task(appEnv.windowAppeared)
        }
        .commands {
            SidebarCommands()
            ToolbarCommands()
            ImportFromDevicesCommands()

            //TextEditingCommands()
            //TextFormattingCommands()

            CommandMenu("Fair") {
                Button("Reload") {
                    Task { await appEnv.reloadResults() }
                }
                .keyboardShortcut("R")

                Button("Find") {
                    appEnv.activateFind()
                }
                .keyboardShortcut("F")
            }
        }
    }
}

/// The manager for the current app fair
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
open class FairManager: AppEnvironmentObject {
    @AppStorage("hubHost") open var hubHost = "https://api.github.com"
    @AppStorage("hubToken") open var hubToken = ""
    @AppStorage("hubOrg") open var hubOrg = "appfair"
    @AppStorage("hubRepo") open var hubRepo = "App"

    @AppStorage("appsTable") open var appsTable = false

    @Published open var searchText: String = ""
    @Published open var searchSelected: Bool = false
    @Published open var errors: [Error] = []
    @Published open var releases: [FairHub.ReleaseInfo] = []
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public extension FairManager {
    typealias Item = URL

    var hub: FairHub {
        FairHub(baseURL: URL(string: hubHost)!, authToken: hubToken.isEmpty ? nil : hubToken)
    }

    var listReleases: FairHub.ListReleasesRequest {
        FairHub.ListReleasesRequest(org: hubOrg, repo: hubRepo)
    }

    func windowAppeared() async {
        await reloadResults()
    }

    func activateFind() {
        print("### ", #function)
        self.searchSelected = true
    }

    func reloadResults() async {
        self.releases = []

        do {
            self.releases = try await hub.requestAsync(listReleases)
        } catch {
            errors.append(error)
        }
    }

    func share(_ item: Item) {
        print("### ", #function)
    }

    func markFavorite(_ item: Item) {
        print("### ", #function)
    }

    func deleteItem(_ item: Item) {
        print("### ", #function)
    }

    func submitCurrentSearchQuery() {
        print("### ", #function)
    }

    func openFilters() {
        print("### ", #function)
    }

    func appCount(_ grouping: AppCategory.Grouping) -> Text? {
        if grouping == .research {
            return Text("10")
        } else {
            return nil
        }
    }

    func badgeCount(for item: SidebarItem) -> Text? {
        nil
    }

    enum SidebarItem {
        case popular
        case favorites
        case recent

        case category(_ group: AppCategory.Grouping)

        case search(_ term: String)

        /// The persistent identifier for this grouping
        var id: String {
            switch self {
            case .popular:
                return "popular"
            case .favorites:
                return "favorites"
            case .recent:
                return "recent"
            case .category(let grouping):
                return "category:" + grouping.rawValue
            case .search(let term):
                return "search:" + term
            }
        }

        var label: some View {
            switch self {
            case .popular:
                return Label("Popular", systemImage: "star")
            case .favorites:
                return Label("Favorites", systemImage: "pin")
            case .recent:
                return Label("Recent", systemImage: "flag") // clock or bolt?
            case .category(let grouping):
                return Label(grouping.localizedTitle, systemImage: grouping.systemImageName)
            case .search(let term):
                return Label("Search: \(term)", systemImage: "magnifyingglass")
            }
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct GeneralSettingsView: View {
    @AppStorage("showPreview") private var showPreview = true
    @AppStorage("fontSize") private var fontSize = 12.0

    var body: some View {
        Form {
            Toggle("Show Previews", isOn: $showPreview)
            Slider(value: $fontSize, in: 9...96) {
                Text("Font Size (\(fontSize, specifier: "%.0f") pts)")
            }
        }
        .padding(20)
        .frame(width: 350, height: 100)
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct AdvancedSettingsView: View {
    @EnvironmentObject var fair: FairManager

    var body: some View {
        Form {
            TextField("Hub", text: fair.$hubHost)
            TextField("Organization", text: fair.$hubOrg)
            TextField("Repository", text: fair.$hubRepo)
            SecureField("Token", text: fair.$hubToken)
            //Text("The token is only needed for advanced API usage. One can be created at:") + Link("XXX", destination: URL(string: fair.hubOrg)!)
        }
        .padding(20)
        .frame(width: 350, height: 100)
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct AppSettingsView: View {
    private enum Tabs: Hashable {
        case general, advanced
    }

    public var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "star")
                }
                .tag(Tabs.advanced)
        }
        .padding(20)
        .frame(width: 375, height: 150)
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct NavigationRootView : View {
    @EnvironmentObject var fair: FairManager

    public var body: some View {
        NavigationView {
            SidebarView()
            AppsListView()
            WelcomeView()
        }
         .searchable(text: $fair.searchText, placement: .automatic) {
             // SuggestionsView()
             // Text("Search suggestions…").keyboardShortcut("S")
         }
         .onSubmit(of: .search) {
             fair.submitCurrentSearchQuery()
         }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct WelcomeView : View, Equatable {
    static let welcomeText = Result { try """
        Welcome to the **App Fair**!
        All are *welcome* here.
        (The Free & Fair place for all your Apps)
        """.atx() }

    public var body: some View {
        Text((try? Self.welcomeText.get()) ?? .init("ERROR"))
            .font(.title)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// The `LSApplicationCategoryType` for an app
public enum AppCategory : String, CaseIterable, Hashable {
    case business = "public.app-category.business"
    case developertools = "public.app-category.developer-tools"
    case education = "public.app-category.education"
    case entertainment = "public.app-category.entertainment"
    case finance = "public.app-category.finance"
    case games = "public.app-category.games"
    case actiongames = "public.app-category.action-games"
    case adventuregames = "public.app-category.adventure-games"
    case arcadegames = "public.app-category.arcade-games"
    case boardgames = "public.app-category.board-games"
    case cardgames = "public.app-category.card-games"
    case casinogames = "public.app-category.casino-games"
    case dicegames = "public.app-category.dice-games"
    case educationalgames = "public.app-category.educational-games"
    case familygames = "public.app-category.family-games"
    case kidsgames = "public.app-category.kids-games"
    case musicgames = "public.app-category.music-games"
    case puzzlegames = "public.app-category.puzzle-games"
    case racinggames = "public.app-category.racing-games"
    case roleplayinggames = "public.app-category.role-playing-games"
    case simulationgames = "public.app-category.simulation-games"
    case sportsgames = "public.app-category.sports-games"
    case strategygames = "public.app-category.strategy-games"
    case triviagames = "public.app-category.trivia-games"
    case wordgames = "public.app-category.word-games"
    case graphicsdesign = "public.app-category.graphics-design"
    case healthcarefitness = "public.app-category.healthcare-fitness"
    case lifestyle = "public.app-category.lifestyle"
    case medical = "public.app-category.medical"
    case music = "public.app-category.music"
    case news = "public.app-category.news"
    case photography = "public.app-category.photography"
    case productivity = "public.app-category.productivity"
    case reference = "public.app-category.reference"
    case socialnetworking = "public.app-category.social-networking"
    case sports = "public.app-category.sports"
    case travel = "public.app-category.travel"
    case utilities = "public.app-category.utilities"
    case video = "public.app-category.video"
    case weather = "public.app-category.weather"
}

public extension AppCategory {
    /// The grouping for an app category
    enum Grouping : String, CaseIterable, Hashable {
        case create
        case research
        case game
        case entertain
        case work
        case live

        /// All the categories that belong to this grouping
        public var categories: [AppCategory] {
            AppCategory.allCases.filter({ $0.groupings.contains(self) })
        }

        public var localizedTitle: LocalizedStringKey {
            switch self {
            case .create: return "Create"
            case .research: return "Knowledge"
            case .game: return "Games"
            case .entertain: return "Sports & Entertainment"
            case .work: return "Work"
            case .live: return "Health & Lifestyle"
            }
        }

        var systemImageName: String {
            switch self {
            case .create: return "paintpalette"
            case .research: return "bolt"
            case .game: return "circle.hexagongrid"
            case .entertain: return "sparkles.tv"
            case .work: return "briefcase"
            case .live: return "bed.double"
            }
        }
    }

    var groupings: Set<Grouping> {
        switch self {
        case .graphicsdesign: return [.create]
        case .photography: return [.create]
        case .productivity: return [.create]
        case .video: return [.create]
        case .developertools: return [.create]

        case .business: return [.work]
        case .finance: return [.work]
        case .utilities: return [.work]

        case .education: return [.research]
        case .weather: return [.research]
        case .reference: return [.research]
        case .news: return [.research]

        case .healthcarefitness: return [.live]
        case .lifestyle: return [.live]
        case .medical: return [.live]
        case .socialnetworking: return [.live]
        case .travel: return [.live]

        case .sports: return [.entertain]
        case .entertainment: return [.entertain]

        case .games: return [.game]
        case .actiongames: return [.game]
        case .adventuregames: return [.game]
        case .arcadegames: return [.game]
        case .boardgames: return [.game]
        case .cardgames: return [.game]
        case .casinogames: return [.game]
        case .dicegames: return [.game]
        case .educationalgames: return [.game]
        case .familygames: return [.game]
        case .kidsgames: return [.game]
        case .musicgames: return [.game]
        case .puzzlegames: return [.game]
        case .racinggames: return [.game]
        case .roleplayinggames: return [.game]
        case .simulationgames: return [.game]
        case .sportsgames: return [.game]
        case .strategygames: return [.game]
        case .triviagames: return [.game]
        case .wordgames: return [.game]
        case .music: return [.game]
        }
    }

}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct SidebarView: View {
    @EnvironmentObject var fair: FairManager

    func shortCut(for grouping: AppCategory.Grouping, offset: Int) -> KeyboardShortcut {
        let index = (AppCategory.Grouping.allCases.enumerated().first(where: { $0.element == grouping })?.offset ?? 0) + offset
        if index > 9 || index < 0 {
            return KeyboardShortcut("0") // otherwise: Fatal error: Can't form a Character from a String containing more than one extended grapheme cluster
        } else {
            let key = Character("\(index)") // the first three are taken by favorites
            return KeyboardShortcut(KeyEquivalent(key))
        }
    }

    var body: some View {
        List {
            Section("Apps") {
                item(.popular).keyboardShortcut("1")
                item(.favorites).keyboardShortcut("2")
                item(.recent).keyboardShortcut("3")
            }

            Section("Categories") {
                ForEach(AppCategory.Grouping.allCases, id: \.self) { grouping in
                    item(.category(grouping)).keyboardShortcut(shortCut(for: grouping, offset: 4))
                }
            }

            Section("Searches") {
                item(.search("Search 1"))
                item(.search("Search 2"))
                item(.search("Search 3"))
            }
        }
        //.symbolVariant(.none)
        //.symbolRenderingMode(.hierarchical)
        .symbolVariant(.fill)
        .symbolRenderingMode(.multicolor)
        .listStyle(.automatic)
        .toolbar {
            tool(.popular)
            tool(.favorites)
            tool(.recent)
            tool(.category(.entertain))
            tool(.category(.research))
            tool(.category(.create))
            tool(.category(.game))
            tool(.category(.live))
            tool(.category(.work))

//            ForEach(AppCategory.Grouping.allCases, id: \.self) { grouping in
//                tool(grouping)
//            }
        }
    }

    func item(_ item: FairManager.SidebarItem) -> some View {
        NavigationLink(destination: AppsListView()) {
            item.label
                .badge(fair.badgeCount(for: item))
                //.font(.title3)
        }
    }

    func tool(_ item: FairManager.SidebarItem) -> some ToolbarContent {
        ToolbarItem(id: item.id, placement: .navigation, showsByDefault: false) {
            Button(action: {
                selectItem(item)
            }, label: {
                item.label
                    //.symbolVariant(.fill)
                    .symbolRenderingMode(.multicolor)
            })
        }
    }

    func selectItem(_ item: FairManager.SidebarItem) {
        print("### SELECTED", item)
    }
}

extension URL {
    func picsum(width: Int, height: Int) -> URL {
        appendingPathComponent("\(width)").appendingPathComponent("\(height)")
    }
}

/// An image that loads asynchronously
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct URLImage : View, Equatable {
    public let url: URL
    public let scale: CGFloat
    public let resizable: ContentMode?


    public init(url: URL, scale: CGFloat = 1.0, resizable: ContentMode? = nil) {
        self.url = url
        self.scale = scale
        self.resizable = resizable
    }

    public var body: some View {
        AsyncImage(url: url, scale: scale) { phase in
            if let image = phase.image {
                if let resizable = resizable {
                    image.resizable().aspectRatio(contentMode: resizable)
                } else {
                    image
                }
            } else if let error = phase.error {
                Label(error.localizedDescription, systemImage: "xmark.octagon")
            } else {
                ProgressView()
            }
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct AppsListView: View {
    @EnvironmentObject var fair: FairManager

    /// Whether to show the view as a table or sidebar
    var displayAsTable: Bool { fair.appsTable }

    var body: some View {
        Group {
            if displayAsTable {
                ReleasesTableView()
            } else {
                ReleasesListView()
            }
        }
        .toolbar {
            Button(action: { fair.appsTable.toggle() }) {
                Image(systemName: "line.horizontal.3.decrease.circle")
            }
        }
    }
}


@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct ReleasesListView: View {
    /// TODO: also try https://unsplash.com
    @State var allImageURLs = (1000...1100).compactMap({ URL(string: "https://picsum.photos/id/\($0)") })
    @EnvironmentObject var fair: FairManager

    var body: some View {
        List(allImageURLs, id: \.self) { url in
            NavigationLink(destination: ImageDetailsView(url: url)) {
                HStack {
                    URLImage(url: url.picsum(width: 40, height: 40))
                        .frame(width: 40, height: 40)

                    Text("Image #\(url.lastPathComponent)")
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        fair.share(url)
                    } label: {
                        Label("Share", systemImage: "shareplay")
                    }
                    .tint(.mint)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        fair.markFavorite(url)
                    } label: {
                        Label("Favorite", systemImage: "pin")
                    }
                    .tint(.orange)

                    Button {
                        fair.deleteItem(url)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)

                }
            }
        }
        .refreshable {
            await fair.reloadResults()
        }
        .navigationTitle("Apps")
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct MessageDetailsView: View {
    let message: String

    var body: some View {
        Text("Details for \(message)")
            .font(.largeTitle)
            .toolbar {
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct ImageDetailsView: View {
    let url: URL

    var body: some View {
        URLImage(url: url.picsum(width: 1000, height: 1000), resizable: ContentMode.fill)
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct ReleasesTableView: View {
    @EnvironmentObject var fair: FairManager

    @State private var selection: FairHub.ReleaseInfo.ID? = nil

    @State private var sortOrder = [KeyPathComparator(\FairHub.ReleaseInfo.created_at)]


    //            public var node_id: String
    //            public var name: String
    //            public var label: String
    //            public var url: URL
    //            public var browser_download_url: URL
    //            public var uploader: Uploader
    //            public var content_type: String
    //            public var state: String // e.g., "uploaded"
    //            public var size: Int64
    //            public var download_count: Int64
    //            public var created_at: Date
    //            public var updated_at: Date

    var body: some View {
        Table(fair.releases, selection: $selection, sortOrder: $sortOrder) {
            Group {
                TableColumn("Name", value: \FairHub.ReleaseInfo.name)

                TableColumn("Created", value: \FairHub.ReleaseInfo.created_at, comparator: DateComparator()) { release in
                    Text(release.created_at.localizedDate(dateStyle: .short, timeStyle: .short))
                }
                TableColumn("Published", value: \FairHub.ReleaseInfo.published_at, comparator: DateComparator()) { release in
                    Text(release.published_at.localizedDate(dateStyle: .short, timeStyle: .short))
                }
            }

            Group {
                TableColumn("State", value: \FairHub.ReleaseInfo.assets.first?.state, comparator: StringComparator()) { release in
                    Text(release.assets.first?.state ?? "N/A")
                }
                TableColumn("Downloads", value: \FairHub.ReleaseInfo.assets.first?.download_count, comparator: NumericComparator()) { release in
                    Text(release.assets.first?.download_count.localizedNumber() ?? "N/A")
                }
                TableColumn("Size", value: \FairHub.ReleaseInfo.assets.first?.size, comparator: NumericComparator()) { release in
                    Text(release.assets.first?.size.localizedByteCount(countStyle: .file) ?? "N/A")
                }
            }

            Group {
                TableColumn("Draft", value: \FairHub.ReleaseInfo.draft, comparator: BoolComparator()) { release in
                    Toggle(isOn: .constant(release.draft)) { EmptyView () }
                }
                TableColumn("Pre-Release", value: \FairHub.ReleaseInfo.prerelease.description) { release in
                    Toggle(isOn: .constant(release.prerelease)) { EmptyView () }
                }
            }

            Group {
//                //downloadColumn
                TableColumn("Tag", value: \FairHub.ReleaseInfo.tag_name)
                TableColumn("Info", value: \FairHub.ReleaseInfo.body) { release in
                    Text((try? release.body.atx()) ?? "No info")
                }
            }
        }
        .onChange(of: sortOrder) {
            fair.releases.sort(using: $0)
        }
    }

//    private var downloadColumn: TableColumn {
//        TableColumn("Download", value: \FairHub.ReleaseInfo.assets.first?.browser_download_url.lastPathComponent) { release in
//            //Text(release.assets.first?.state ?? "N/A")
//            //Toggle(isOn: .constant(release.draft)) { EmptyView () }
//            if let url = release.assets.first?.browser_download_url {
//                Link(url: url)
//            }
//        }
//    }

}


@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension SortComparator {
    func reorder(_ result: ComparisonResult) -> ComparisonResult {
        switch (order, result) {
        case (_, .orderedSame): return .orderedSame
        case (.forward, .orderedAscending): return .orderedAscending
        case (.reverse, .orderedAscending): return .orderedDescending
        case (.forward, .orderedDescending): return .orderedDescending
        case (.reverse, .orderedDescending): return .orderedAscending
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct BoolComparator : SortComparator {
    var order: SortOrder = SortOrder.forward

    func compare(_ lhs: Bool, _ rhs: Bool) -> ComparisonResult {
        switch (lhs, rhs) {
        case (true, true): return reorder(.orderedSame)
        case (false, false): return reorder(.orderedSame)
        case (true, false): return reorder(.orderedAscending)
        case (false, true): return reorder(.orderedAscending)
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct DateComparator : SortComparator {
    var order: SortOrder = SortOrder.forward

    func compare(_ lhs: Date, _ rhs: Date) -> ComparisonResult {
        lhs < rhs ? reorder(.orderedAscending)
        : lhs > rhs ? reorder(.orderedDescending)
        : .orderedSame
    }
}


@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct StringComparator : SortComparator {
    var order: SortOrder = SortOrder.forward

    func compare(_ lhs: String?, _ rhs: String?) -> ComparisonResult {
        reorder((lhs ?? "").localizedCompare(rhs ?? ""))
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct NumericComparator : SortComparator {
    var order: SortOrder = SortOrder.forward

    func compare(_ lhs: Int64?, _ rhs: Int64?) -> ComparisonResult {
        lhs ?? 0 < rhs ?? 0 ? reorder(.orderedAscending) : lhs ?? 0 > rhs ?? 0 ? reorder(.orderedDescending) : .orderedSame
    }
}

