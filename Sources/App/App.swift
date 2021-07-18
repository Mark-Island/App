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

@available(macOS 12.0, iOS 15.0, *)
@main public enum AppContainer : FairApp.FairContainer {
    public static func main() throws { try launch() }
}

// Everything above this line must remain unmodified.

// Define your app in an extension of `AppContainer`

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public extension AppContainer {

    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        WindowGroup {
            NavigationRootView()
                .environmentObject(store)
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
                    let start = CFAbsoluteTimeGetCurrent()
                    Task {
                        await appEnv.loadResults(cache: .reloadIgnoringLocalAndRemoteCacheData)
                        let end = CFAbsoluteTimeGetCurrent()
                        print("reload:", end - start)
                    }
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

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public typealias AppEnv = FairManager

/// A released app
public struct AppRelease : Hashable, Identifiable {
    let repo: FairHub.RepositoryInfo
    let rel: FairHub.ReleaseInfo

    public var id: Int64 { rel.id }
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
    @Published open var errors: [(AppFailure, Error)] = []

    @Published open var apps: [AppRelease] = []
    @Published open var runs: [FairHub.WorkflowRun] = []
}

/// The reason why an action failed
public enum AppFailure {
    case reloadFailed

    var failureReason: LocalizedStringKey? {
        switch self {
        case .reloadFailed: return "Reload Failed"
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public extension FairManager {
    typealias Item = URL

    var hub: FairHub {
        FairHub(baseURL: URL(string: hubHost)!, authToken: hubToken.isEmpty ? nil : hubToken)
    }

    var listReleases: FairHub.ListReleasesRequest {
        .init(org: hubOrg, repo: hubRepo)
    }

    var listForks: FairHub.GetRepostoryForksRequest {
        .init(org: hubOrg, repo: hubRepo)
    }

    var listRuns: FairHub.ListWorkflowRunsRequest {
        .init(org: hubOrg, repo: hubRepo)
    }

    func windowAppeared() async {
        await loadResults(cache: .useProtocolCachePolicy)
    }

    func activateFind() {
        print("### ", #function)
        self.searchSelected = true
    }

    func fetchReleases(cache: URLRequest.CachePolicy? = nil) async throws -> [FairHub.ReleaseInfo] {
        try await hub.requestAsync(listReleases, cache: cache)
    }

    func fetchForks(cache: URLRequest.CachePolicy? = nil) async throws -> [FairHub.RepositoryInfo] {
        try await hub.requestAsync(listForks, cache: cache)
    }

    func fetchRuns(cache: URLRequest.CachePolicy? = nil) async throws -> FairHub.ListWorkflowRunsRequest.Response {
        try await hub.requestAsync(listRuns, cache: cache)
    }

    /// Matches up the list of releases with the list of forks
    func match(_ releases: [FairHub.ReleaseInfo], _ forks: [FairHub.RepositoryInfo]) -> [AppRelease] {
        let fks = Dictionary(grouping: forks, by: \.owner.login)
        var rels: [AppRelease] = []
        for release in releases {
            if let fork = fks[release.tag_name]?.first {
                rels.append(AppRelease(repo: fork, rel: release))
            }
        }
        return rels
    }

    func loadResults(cache: URLRequest.CachePolicy) async {
        self.apps = []
        self.runs = []

        do {
            /// perform all the fetches simultaneously and aggregate the results
            async let rels = fetchReleases(cache: cache)
            async let forks = fetchForks(cache: cache)
            async let runs = fetchRuns(cache: cache)
            (self.apps, self.runs) = try await (match(rels, forks), runs.workflow_runs)
        } catch {
            errors.append((.reloadFailed, error))
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
                return grouping.label
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
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct AdvancedSettingsView: View {
    @EnvironmentObject var fair: FairManager

    func checkButton(_ parts: String...) -> some View {
        EmptyView()
//        Group {
//            Image(systemName: "checkmark.square.fill").aspectRatio(contentMode: .fit).foregroundColor(.green)
//            Image(systemName: "xmark.square.fill").aspectRatio(contentMode: .fit).foregroundColor(.red)
//        }
    }

    var body: some View {
        VStack {
            Form {
                HStack {
                    TextField("Hub", text: fair.$hubHost)
                    checkButton(fair.hubHost)
                }
                HStack {
                    TextField("Organization", text: fair.$hubOrg)
                    checkButton(fair.hubHost, fair.hubOrg)
                }
                HStack {
                    TextField("Repository", text: fair.$hubRepo)
                    checkButton(fair.hubHost, fair.hubOrg, fair.hubRepo)
                }
                HStack {
                    SecureField("Token", text: fair.$hubToken)
                }

                Text(atx: "The token is optional, and is only needed for development or advanced usage. One can be created at your [GitHub Personal access token](https://github.com/settings/tokens) setting").multilineTextAlignment(.trailing)

                HelpButton(url: "https://github.com/settings/tokens")
            }
            .padding(20)
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct HelpButton : View {
    let url: String
    @Environment(\.openURL) var openURL

    public var body: some View {
        Button(role: .none, action: {
            if let url = URL(string: url) {
                openURL(url)
            }
        }) {
            //Image(systemName: "questionmark.circle.fill")
            Image(systemName: "questionmark")
        }
        .buttonStyle(.bordered)
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store: Store) -> some SwiftUI.View {
        AppSettingsView().environmentObject(store)
    }
}

/// The shared app environment
@available(macOS 12.0, iOS 15.0, *)
@MainActor public final class Store: AppStoreObject {
    @AppStorage("someToggle") public var someToggle = false
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct AppSettingsView: View {
    public enum Tabs: Hashable {
        case general, advanced
    }

    public var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }
                .tag(Tabs.general)
            AdvancedSettingsView()
                .tabItem { Label("Advanced", systemImage: "star") }
                .tag(Tabs.advanced)
        }
        .padding(20)
        .frame(width: 500)
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct NavigationRootView : View {
    @EnvironmentObject var fair: FairManager

    public var body: some View {
        if fair.appsTable {
            NavigationView {
                SidebarView()
                VSplitView {
                    AppsListView()
                    WelcomeView()
                }
            }
        } else {
            NavigationView {
                SidebarView()
                AppsListView()
                WelcomeView()
            }
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct WelcomeView : View, Equatable {
    public var body: some View {
        VStack {
            Text(atx: """
            Welcome to the **App Fair**!
            """)
                .font(.title)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Spacer()
            //WelcomeAnimationView()
                //.overlay(Rectangle)
        }
    }
}

public extension AppCategory {
    /// The grouping for an app category
    enum Grouping : String, CaseIterable, Hashable {
        case create
        case research
        case game
        case entertain
        case live
        case work

        /// All the categories that belong to this grouping
        public var categories: [AppCategory] {
            AppCategory.allCases.filter({ $0.groupings.contains(self) })
        }

        public var label: Label<Text, Image> {
            switch self {
            case .create: return Label("Create", image: "custom.paintpalette.fill")
            //case .create: return Label("Create", systemImage: "paintpalette")
            case .research: return Label("Read", systemImage: "bolt")
            case .game: return Label("Play", systemImage: "circle.hexagongrid")
            case .entertain: return Label("Watch", systemImage: "sparkles.tv")
            case .live: return Label("Live", systemImage: "house")
            case .work: return Label("Work", systemImage: "briefcase")
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
        NavigationLink(destination: AppsListView(item: item)) {
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

/// An image that loads from a URL, either synchronously or asynchronously
public struct URLImage : View, Equatable {
    /// Whether the image should be loaded synchronously or asynchronously
    public let sync: Bool
    /// The URL from which to load
    public let url: URL
    /// The scale of the image
    public let scale: CGFloat
    /// Whether the image should be resizable or not
    public let resizable: ContentMode?

    public init(sync: Bool = false, url: URL, scale: CGFloat = 1.0, resizable: ContentMode? = nil) {
        self.sync = sync
        self.url = url
        self.scale = scale
        self.resizable = resizable
    }

    public var body: some View {
        if sync == false, #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) {
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
        } else { // load the image synchronously
            if let img = UXImage(contentsOf: url) {
                if let resizable = resizable {
                    Image(uxImage: img).resizable().aspectRatio(contentMode: resizable)
                } else {
                    Image(uxImage: img)
                }
            } else {
                Label("Error Loading Image", systemImage: "xmark.octagon")
            }
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct AppsListView: View {
    @EnvironmentObject var fair: FairManager

    var item: FairManager.SidebarItem? = nil

    /// Whether to show the view as a table or sidebar
    var displayAsTable: Bool { fair.appsTable }


    var body: some View {
        Group {
            if displayAsTable {
                switch item {
                case .recent:
                    ActionsTableView()
                default:
                    ReleasesTableView()
                }
            } else {
                ReleasesListView()
            }
        }
        .searchable(text: $fair.searchText, placement: .automatic) {
            // SuggestionsView()
            // Text("Search suggestions…").keyboardShortcut("S")
        }
        .onSubmit(of: .search) {
            fair.submitCurrentSearchQuery()
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
            await fair.loadResults(cache: .reloadRevalidatingCacheData)
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
struct ActionsTableView : View, TableColumnFactory {
    typealias TableItemRoot = FairHub.WorkflowRun
    @EnvironmentObject var fair: FairManager
    @State private var selection: FairHub.WorkflowRun.ID? = nil
    @State private var sortOrder = [KeyPathComparator(\FairHub.WorkflowRun.created_at)]

    var body: some View {
        Table(fair.runs, selection: $selection, sortOrder: $sortOrder) {
            Group {
                //strColumn(named: "Name", path: \FairHub.WorkflowRun.name)
                ostrColumn(named: "Owner", path: \.head_repository?.owner.login)

                strColumn(named: "Hash", path: \.head_sha)
                strColumn(named: "Status", path: \.status)
                strColumn(named: "Conclusion", path: \.conclusion)

                numColumn(named: "Run #", path: \.run_number)
                strColumn(named: "Author", path: \.head_commit.author.name)
                dateColumn(named: "Created", path: \.created_at)
                dateColumn(named: "Updates", path: \.updated_at)
            }
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .font(Font.body.monospacedDigit())
        .onChange(of: sortOrder) {
            fair.runs.sort(using: $0)
        }
    }

}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct ReleasesTableView : View, TableColumnFactory {
    typealias TableItemRoot = AppRelease
    @EnvironmentObject var fair: FairManager
    @State private var selection: AppRelease.ID? = nil
    @State private var sortOrder = [KeyPathComparator(\AppRelease.rel.created_at)]

    var body: some View {
        Table(fair.apps, selection: $selection, sortOrder: $sortOrder) {
            Group {
                TableColumn("", value: \AppRelease.repo.owner.avatar_url, comparator: StringComparator()) { item in
                    if let avatar_url = item.repo.owner.avatar_url, let url = URL(string: avatar_url) {
                        URLImage(url: url, resizable: .fit)
                    }
                }
            }

            Group {
                strColumn(named: "Organization", path: \.repo.owner.login)
                strColumn(named: "Name", path: \.rel.name)
                dateColumn(named: "Created", path: \.rel.created_at)
                dateColumn(named: "Published", path: \.rel.published_at)
            }

            Group {
                numColumn(named: "Stars", path: \.repo.stargazers_count)
                numColumn(named: "Issues", path: \.repo.open_issues_count)
                numColumn(named: "Forks", path: \.repo.forks)
            }

            Group {
                ostrColumn(named: "State", path: \.rel.assets.first?.state)
                onumColumn(named: "Downloads", path: \.rel.assets.first?.download_count)

                TableColumn("Size", value: \AppRelease.rel.assets.first?.size, comparator: OptionalNumericComparator()) { release in
                    Text(release.rel.assets.first?.size.localizedByteCount(countStyle: .file) ?? "N/A")
                }
            }

            Group {
                boolColumn(named: "Draft", path: \.rel.draft)
                boolColumn(named: "Pre-Release", path: \.rel.prerelease)
            }

            Group {
                TableColumn("Download", value: \AppRelease.rel.assets.first?.browser_download_url.lastPathComponent, comparator: StringComparator()) { release in
                    //Text(release.assets.first?.state ?? "N/A")
                    //Toggle(isOn: .constant(release.draft)) { EmptyView () }
                    if let asset = release.rel.assets.first {
                        Link("Download \(asset.size.localizedByteCount(countStyle: .file))", destination: asset.browser_download_url)
                    }
                }
                TableColumn("Tag", value: \AppRelease.rel.tag_name)
                TableColumn("Info", value: \AppRelease.rel.body) { release in
                    Text((try? release.rel.body.atx()) ?? "No info")
                }
            }
        }
        .tableStyle(.inset(alternatesRowBackgrounds: false))
        .font(Font.body.monospacedDigit())
        .onChange(of: sortOrder) {
            fair.apps.sort(using: $0)
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
protocol TableColumnFactory {
    associatedtype TableItemRoot : Identifiable
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension TableColumnFactory {
    func dateColumn(named key: LocalizedStringKey, path: KeyPath<TableItemRoot, Date>) -> TableColumn<TableItemRoot, KeyPathComparator<TableItemRoot>, Text, Text> {
        TableColumn(key, value: path, comparator: DateComparator()) { release in
            Text(release[keyPath: path].localizedDate(dateStyle: .short, timeStyle: .short))
        }
    }

    func numColumn<T: BinaryInteger>(named key: LocalizedStringKey, path: KeyPath<TableItemRoot, T>) -> TableColumn<TableItemRoot, KeyPathComparator<TableItemRoot>, Text, Text> {
        TableColumn(key, value: path, comparator: NumericComparator()) { release in
            Text(release[keyPath: path].localizedNumber())
        }
    }

    func boolColumn(named key: LocalizedStringKey, path: KeyPath<TableItemRoot, Bool>) -> TableColumn<TableItemRoot, KeyPathComparator<TableItemRoot>, Toggle<EmptyView>, Text> {
        TableColumn(key, value: path, comparator: BoolComparator()) { release in
            Toggle(isOn: .constant(release[keyPath: path])) { EmptyView () }
        }
    }

    /// Non-optional string column
    func strColumn(named key: LocalizedStringKey, path: KeyPath<TableItemRoot, String>) -> TableColumn<TableItemRoot, KeyPathComparator<TableItemRoot>, Text, Text> {
        TableColumn(key, value: path, comparator: .localizedStandard) { release in
            Text(release[keyPath: path])
        }
    }

    func ostrColumn(named key: LocalizedStringKey, path: KeyPath<TableItemRoot, String?>) -> TableColumn<TableItemRoot, KeyPathComparator<TableItemRoot>, Text, Text> {
        TableColumn(key, value: path, comparator: StringComparator()) { release in
            Text(release[keyPath: path] ?? "")
        }
    }

    func onumColumn<T: BinaryInteger>(named key: LocalizedStringKey, path: KeyPath<TableItemRoot, T?>) -> TableColumn<TableItemRoot, KeyPathComparator<TableItemRoot>, Text, Text> {
        TableColumn(key, value: path, comparator: NumComparator()) { release in
            Text(release[keyPath: path]?.localizedNumber() ?? "")
        }
    }
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
struct NumericComparator<N: Numeric & Comparable> : SortComparator {
    var order: SortOrder = SortOrder.forward

    func compare(_ lhs: N, _ rhs: N) -> ComparisonResult {
        lhs < rhs ? reorder(.orderedAscending) : lhs > rhs ? reorder(.orderedDescending) : .orderedSame
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct NumComparator<N: Numeric & Comparable> : SortComparator {
    var order: SortOrder = SortOrder.forward

    func compare(_ lhs: N?, _ rhs: N?) -> ComparisonResult {
        guard let lhs = lhs, let rhs = rhs else { return .orderedSame }
        return lhs < rhs ? reorder(.orderedAscending) : lhs > rhs ? reorder(.orderedDescending) : .orderedSame
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct OptionalNumericComparator : SortComparator {
    var order: SortOrder = SortOrder.forward

    func compare(_ lhs: Int64?, _ rhs: Int64?) -> ComparisonResult {
        lhs ?? 0 < rhs ?? 0 ? reorder(.orderedAscending) : lhs ?? 0 > rhs ?? 0 ? reorder(.orderedDescending) : .orderedSame
    }
}
