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
    var settingsView : some View {
        AppSettingsView().environmentObject(appEnv)
    }

    var rootScene: some Scene {
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

            AppFairCommands()
        }
    }
}

public extension Bundle {
    /// The URL for the App's resource bundle
    static var appBundleURL: URL! {
        Bundle.module.url(forResource: "Bundle", withExtension: nil)
    }
}

/// An app that is available to download.
///
/// This is a synthesis of two separate API responses: the `repo`, which is the host to the app itself, and the `rel`, which is the release build for which the app as part of the upsteam repo.
public struct AppRelease : Hashable, Identifiable {
    public let repository: FairHub.RepositoryInfo
    public let release: FairHub.ReleaseInfo

    public init(repository: FairHub.RepositoryInfo, release: FairHub.ReleaseInfo) {
        self.repository = repository
        self.release = release
    }

    public var id: Int64 { release.id }
}

extension AppRelease {
    var name: String? {
        let orgname = repository.owner.login
        let relname = release.name
        if orgname != relname {
            print("internal error: organization name:", orgname, "mismatched release name:", relname)
            return nil
        }

        return repository.owner.appName
    }
}

/// The current selected instance, which can either be a release or a workflow run
enum Selection {
    case app(AppRelease)
    case run(FairHub.WorkflowRun)
}

/// The manager for the current app fair
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
@MainActor public final class AppEnv: AppEnvironmentObject {
    @AppStorage("hubHost") public var hubHost = "https://api.github.com"
    @AppStorage("hubToken") public var hubToken = ""
    @AppStorage("hubOrg") public var hubOrg = "appfair"
    @AppStorage("hubRepo") public var hubRepo = "App"

    @Published public var errors: [(AppFailure?, Error)] = []
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct AppFairCommands: Commands {
    @FocusedBinding(\.selection) private var selection: Selection??
    @FocusedBinding(\.reloadCommand) private var reloadCommand: (() async -> ())?

    var body: some Commands {

//        switch selection {
//        case .app(let app):
//        case .run(let run):
//        case .none:
//        case .some(.none):
//        }

//        CommandMenu("Fair") {
//            Button("Find") {
//                appEnv.activateFind()
//            }
//            .keyboardShortcut("F")
//        }

//        CommandGroup(before: .newItem) {
//            ShareAppButton()
//        }

        CommandMenu("Fair") {
            Button("Reload Apps") {
                guard let cmd = reloadCommand else {
                    print("no reload command")
                    return
                }
                let start = CFAbsoluteTimeGetCurrent()
                Task {
                    await cmd()
                    let end = CFAbsoluteTimeGetCurrent()
                    print("reloaded:", end - start)
                }
            }
            .keyboardShortcut("R")
            .disabled(reloadCommand == nil)
        }
    }
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
public extension AppEnv {
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
        //await loadResults(cache: .useProtocolCachePolicy)
    }

    func activateFind() {
        print("### ", #function) // TODO: is there a way to focus the search field?
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
        let fks = Dictionary(grouping: forks, by: \.owner.login) // index the fork by owner login (i.e., the org name) so we can match the releases list
        var rels: [AppRelease] = []
        for release in releases {
            if let fork = fks[release.tag_name]?.first {
                rels.append(AppRelease(repository: fork, release: release))
            }
        }
        return rels
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
    @EnvironmentObject var appEnv: AppEnv

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
                    TextField("Hub", text: appEnv.$hubHost)
                    checkButton(appEnv.hubHost)
                }
                HStack {
                    TextField("Organization", text: appEnv.$hubOrg)
                    checkButton(appEnv.hubHost, appEnv.hubOrg)
                }
                HStack {
                    TextField("Repository", text: appEnv.$hubRepo)
                    checkButton(appEnv.hubHost, appEnv.hubOrg, appEnv.hubRepo)
                }
                HStack {
                    SecureField("Token", text: appEnv.$hubToken)
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
    @EnvironmentObject var appEnv: AppEnv

    public var body: some View {
        NavigationView {
            SidebarView()
            AppsListView()
            DetailView()
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct DetailView : View {
    @FocusedBinding(\.selection) private var selection: Selection??

    public var body: some View {
        VStack {
            //WelcomeAnimationView()

            switch selection {
            case .app(let app):
                ScrollView { AppInfoView(app: app) }
            case .run(let run):
                ScrollView { RunInfoView(run: run) }
            case .none:
                Text("No Selection").font(.title)
            case .some(.none):
                Text("No Selection").font(.title)
            }
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct AppInfoView : Equatable, View {
    let app: AppRelease

    var body : some View {
        Form {
            GroupBox("Release") {
                TextField("Name", text: .constant(app.release.name))
            }

            GroupBox("Repository") {
                TextField("Organization", text: .constant(app.repository.name))
                TextField("Owner", text: .constant(app.repository.owner.login))
                TextField("Type", text: .constant(app.repository.owner.type))
                //TextField("ID", text: .constant(app.repository.owner.id))
            }
        }
        .padding()
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct RunInfoView : Equatable, View {
    let run: FairHub.WorkflowRun

    var body : some View {
        Form {
            GroupBox("Run") {
                TextField("Name", text: .constant(run.name))
            }
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
    @EnvironmentObject var appEnv: AppEnv

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

//            Section("Searches") {
//                item(.search("Search 1"))
//                item(.search("Search 2"))
//                item(.search("Search 3"))
//            }
        }
        //.symbolVariant(.none)
        //.symbolRenderingMode(.hierarchical)
        //.symbolVariant(.circle) // note that these can be stacked
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

    func item(_ item: AppEnv.SidebarItem) -> some View {
        NavigationLink(destination: AppsListView(item: item)) {
            item.label
                .badge(appEnv.badgeCount(for: item))
                //.font(.title3)
        }
    }

    func tool(_ item: AppEnv.SidebarItem) -> some ToolbarContent {
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

    func selectItem(_ item: AppEnv.SidebarItem) {
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
    /// Whether a progress placeholder should be used
    public let showProgress: Bool

    public init(sync: Bool = false, url: URL, scale: CGFloat = 1.0, resizable: ContentMode? = nil, showProgress: Bool = false) {
        self.sync = sync
        self.url = url
        self.scale = scale
        self.resizable = resizable
        self.showProgress = showProgress
    }

    public var body: some View {
        if sync == false, #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) {
            AsyncImage(url: url, scale: scale) { phase in
                if let image = phase.image {
                    if let resizable = resizable {
                        image
                            .resizable(resizingMode: .stretch)
                            .aspectRatio(contentMode: resizable)
                    } else {
                        image
                    }
                } else if let error = phase.error {
                    Label(error.localizedDescription, systemImage: "xmark.octagon")
                } else if showProgress == true {
                    ProgressView().progressViewStyle(.automatic)
                    //Color.gray.opacity(0.5)
                } else {
                    ProgressView().progressViewStyle(.automatic).hidden()
                }
            }
        } else { // load the image synchronously
            if let img = UXImage(contentsOf: url) {
                if let resizable = resizable {
                    Image(uxImage: img)
                        .resizable(resizingMode: .stretch)
                        .aspectRatio(contentMode: resizable)
                } else {
                    Image(uxImage: img)
                }
            } else {
                Label("Error Loading Image", systemImage: "xmark.octagon")
            }
        }
    }
}


extension FocusedValues {

//    private struct FocusedGardenKey: FocusedValueKey {
//        typealias Value = Binding<Selection?>
//    }
//
//    var garden: Binding<Garden>? {
//        get { self[FocusedGardenKey.self] }
//        set { self[FocusedGardenKey.self] = newValue }
//    }

    private struct FocusedSelection: FocusedValueKey {
        typealias Value = Binding<Selection?>
    }

    var selection: Binding<Selection?>? {
        get { self[FocusedSelection.self] }
        set { self[FocusedSelection.self] = newValue }
    }

    private struct FocusedReloadCommand: FocusedValueKey {
        typealias Value = Binding<() async -> ()>
    }

    var reloadCommand: Binding<() async -> ()>? {
        get { self[FocusedReloadCommand.self] }
        set { self[FocusedReloadCommand.self] = newValue }
    }


}


@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct DisplayModePicker: View {
    @Binding var mode: AppsListView.ViewMode

    var body: some View {
        Picker("Display Mode", selection: $mode) {
            ForEach(AppsListView.ViewMode.allCases) { viewMode in
                viewMode.label
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension AppsListView.ViewMode {
    var labelContent: (name: String, systemImage: String) {
        switch self {
        case .table:
            return ("Table", "tablecells")
        case .gallery:
            return ("Gallery", "photo")
        }
    }

    var label: some View {
        let content = labelContent
        return Label(content.name, systemImage: content.systemImage)
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct AppsListView: View {
    @EnvironmentObject var appEnv: AppEnv
    @SceneStorage("viewMode") private var mode: ViewMode = .table

    enum ViewMode: String, CaseIterable, Identifiable {
        var id: Self { self }
        case table
        case gallery
    }

    var item: AppEnv.SidebarItem? = nil

    var body: some View {
        Group {
            if mode == .table {
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
//        .padding()
//        .focusedSceneValue(\.selection, $selection)
        .toolbar(id: "AppsListView") {
            ToolbarItem(id: "DisplayModePicker", placement: .navigation, showsByDefault: true) {
                DisplayModePicker(mode: $mode)
            }
        }
    }
}


@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct ReleasesListView: View {
    /// TODO: also try https://unsplash.com
    @State var allImageURLs = (1000...1100).compactMap({ URL(string: "https://picsum.photos/id/\($0)") })
    @EnvironmentObject var appEnv: AppEnv

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
                        appEnv.share(url)
                    } label: {
                        Label("Share", systemImage: "shareplay")
                    }
                    .tint(.mint)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        appEnv.markFavorite(url)
                    } label: {
                        Label("Favorite", systemImage: "pin")
                    }
                    .tint(.orange)

                    Button {
                        appEnv.deleteItem(url)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)

                }
            }
        }
//        .refreshable {
//            await appEnv.loadResults(cache: .reloadRevalidatingCacheData)
//        }
//        .navigationTitle("Apps")
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
struct ActionsTableView : View, ItemTableView {
    @EnvironmentObject var appEnv: AppEnv
    typealias TableElement = FairHub.WorkflowRun
    @State var selection: TableElement.ID? = nil
    @State var sortOrder = [KeyPathComparator(\TableElement.created_at)]
    @State var searchText: String = ""
    @State var items: [TableElement] = []

    var body: some View {
        table
            .task { await fetchRuns() }
    }

    func fetchRuns(cache: URLRequest.CachePolicy? = nil) async {
        self.items = []
        do {
            self.items = try await appEnv.fetchRuns(cache: cache).workflow_runs
        } catch {
            appEnv.errors.append((nil, error))
        }
    }

//    var columns: some TableColumnContent {
//        let ownerColumn = ostrColumn(named: "Owner", path: \.head_repository?.owner.login)
//        return Group {
//            ownerColumn
//        }
//    }

    var table: some View {
        let imageColumn = TableColumn("", value: \TableElement.head_repository?.owner.avatar_url, comparator: StringComparator()) { item in
            if let avatar_url = item.head_repository?.owner.avatar_url, let url = URL(string: avatar_url) {
                URLImage(url: url, resizable: .fit)
            }
        }

        let ownerColumn = ostrColumn(named: "Owner", path: \.head_repository?.owner.login)
        let statusColumn = ostrColumn(named: "Status", path: \.status?.rawValue)
        let conclusionColumn = ostrColumn(named: "Conclusion", path: \.conclusion?.rawValue)
        let runColumn = numColumn(named: "Run #", path: \.run_number)
        let authorColumn = strColumn(named: "Author", path: \.head_commit.author.name)
        let createdColumn = dateColumn(named: "Created", path: \.created_at)
        let updatedColumn = dateColumn(named: "Updated", path: \.updated_at)
        let hashColumn = TableColumn("Hash", value: \TableElement.head_sha) { item in
            Text(item.head_sha).font(Font.system(.body, design: .monospaced))
        }

        let columns = Group {
            imageColumn.width(50)
            ownerColumn
            statusColumn
            conclusionColumn
            runColumn
            authorColumn
            createdColumn
            updatedColumn
            hashColumn.width(ideal: 350) // about the right length to fit a SHA-1 hash
        }

        return Table(selection: $selection, sortOrder: $sortOrder, columns: { columns }, rows: {
            ForEach(search(self.items)) { item in
                TableRow(item)
                    //.itemProvider { items.itemProvider }
            }
//            .onInsert(of: [Item.draggableType]) { index, providers in
//                Item.fromItemProviders(providers) { items in
//                    item.items.insert(contentsOf: items, at: index)
//                }
//            }
        })
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .font(Font.body.monospacedDigit())
        .onChange(of: sortOrder) {
            self.items.sort(using: $0)
        }
        .focusedSceneValue(\.selection, .constant(itemSelection))
        .focusedSceneValue(\.reloadCommand, .constant({
            await fetchRuns(cache: .reloadIgnoringLocalAndRemoteCacheData)
        }))
        .searchable(text: $searchText)
    }

    /// The currently selected item
    var itemSelection: Selection? {
        guard let item = items.first(where: { $0.id == selection }) else {
            return nil
        }

        return Selection.run(item)
    }

    private func search(_ items: [TableElement]) -> [TableElement] {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? items
        : items.filter { item in
            item.name.localizedCaseInsensitiveContains(searchText) == true
            || item.status?.rawValue.localizedCaseInsensitiveContains(searchText) == true
            || item.conclusion?.rawValue.localizedCaseInsensitiveContains(searchText) == true
            || item.head_commit.author.name.localizedCaseInsensitiveContains(searchText) == true
            || item.head_sha.contains(searchText) == true
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct ReleasesTableView : View, ItemTableView {
    @EnvironmentObject var appEnv: AppEnv
    typealias TableElement = AppRelease
    @State var selection: TableElement.ID? = nil
    @State var sortOrder = [KeyPathComparator(\TableElement.release.published_at)]
    @State var searchText: String = ""
    @State var items: [TableElement] = []

    var body: some View {
        table
            .task { await fetchApps() }
    }

    func fetchApps(cache: URLRequest.CachePolicy? = nil) async {
        self.items = []
        async let rels = appEnv.fetchReleases(cache: cache)
        async let forks = appEnv.fetchForks(cache: cache)
        do {
            self.items = try await appEnv.match(rels, forks)
        } catch {
            Task { // otherwise warnings about accessing off of the main thread
                appEnv.errors.append((nil, error))
            }
        }
    }

    var table: some View {
        let imageColumn: TableColumn<TableElement, KeyPathComparator<TableElement>, URLImage?, Text> = TableColumn("", value: \TableElement.repository.owner.avatar_url, comparator: StringComparator()) { item in
            if let avatar_url = item.repository.owner.avatar_url, let url = URL(string: avatar_url) {
                URLImage(url: url, resizable: .fit)
            }
        }

        let nameColumn = ostrColumn(named: "Name", path: \.name)

        let createdColumn = dateColumn(named: "Created", path: \.release.created_at)
        let publishedColumn = dateColumn(named: "Published", path: \.release.published_at)
        let starsColumn = numColumn(named: "Stars", path: \.repository.stargazers_count)
        let issuesColumn = numColumn(named: "Issues", path: \.repository.open_issues_count)
        let forksColumn = numColumn(named: "Forks", path: \.repository.forks)
        let stateColumn = ostrColumn(named: "State", path: \.release.assets.first?.state)
        let downloadsColumn = onumColumn(named: "Downloads", path: \.release.assets.first?.download_count)

        let sizeColumn = TableColumn("Size", value: \TableElement.release.assets.first?.size, comparator: OptionalNumericComparator()) { item in
            Text(item.release.assets.first?.size.localizedByteCount(countStyle: .file) ?? "N/A")
        }

        let draftColumn = boolColumn(named: "Draft", path: \.release.draft)
        let preReleaseColumn = boolColumn(named: "Pre-Release", path: \.release.prerelease)

        let downloadColumn = TableColumn("Download", value: \TableElement.release.assets.first?.browser_download_url.lastPathComponent, comparator: StringComparator()) { item in
            //Text(item.assets.first?.state ?? "N/A")
            //Toggle(isOn: .constant(item.draft)) { EmptyView () }
            if let asset = item.release.assets.first {
                Link("Download \(asset.size.localizedByteCount(countStyle: .file))", destination: asset.browser_download_url)
            }
        }
        let tagColumn = TableColumn("Tag", value: \TableElement.release.tag_name)
        let infoColumn = TableColumn("Info", value: \TableElement.release.body) { item in
            Text((try? item.release.body.atx()) ?? "No info")
        }

        let columnGroup1 = Group {
            imageColumn.width(50)
            nameColumn
            sizeColumn
            downloadColumn
            downloadsColumn
            createdColumn
            publishedColumn
        }

        let columnGroup2 = Group {
            starsColumn
            issuesColumn
            forksColumn
            stateColumn
        }

        let columnGroup3 = Group {
            draftColumn
            preReleaseColumn
            tagColumn
            infoColumn
        }

        let columns = Group {
            // these need to be broken up to help the typechecker solve it in a reasonable amount of time
            columnGroup1
            columnGroup2
            columnGroup3
        }

        return Table(selection: $selection, sortOrder: $sortOrder, columns: { columns }, rows: {
            ForEach(search(self.items)) { item in
                TableRow(item)
                    //.itemProvider { items.itemProvider }
            }
//            .onInsert(of: [Item.draggableType]) { index, providers in
//                Item.fromItemProviders(providers) { items in
//                    item.items.insert(contentsOf: items, at: index)
//                }
//            }
        })
        .tableStyle(.inset(alternatesRowBackgrounds: false))
        .font(Font.body.monospacedDigit())
        .onChange(of: sortOrder) {
            self.items.sort(using: $0)
        }
        .focusedSceneValue(\.selection, .constant(itemSelection))
        .focusedSceneValue(\.reloadCommand, .constant({
            await fetchApps(cache: .reloadIgnoringLocalAndRemoteCacheData)
        }))
        .searchable(text: $searchText)
    }

    /// The currently selected item
    var itemSelection: Selection? {
        guard let item = items.first(where: { $0.id == selection }) else {
            return nil
        }

        return Selection.app(item)
    }

    private func search(_ items: [TableElement]) -> [TableElement] {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? items
        : items.filter { item in
            item.repository.name.localizedCaseInsensitiveContains(searchText) == true
            || item.repository.owner.login.localizedCaseInsensitiveContains(searchText) == true
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
protocol ItemTableView {
    associatedtype TableElement : Identifiable

    /// The items that this table holds
    var items: [TableElement] { get nonmutating set }

    /// The current selection, if any
    var selection: TableElement.ID? { get nonmutating set }

    /// The current sort orders
    var sortOrder: [KeyPathComparator<TableElement>] { get nonmutating set }

}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension ItemTableView where Self : View {
}


@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension ItemTableView {

    func dateColumn(named key: LocalizedStringKey, path: KeyPath<TableElement, Date>) -> TableColumn<TableElement, KeyPathComparator<TableElement>, Text, Text> {
        TableColumn(key, value: path, comparator: DateComparator()) { item in
            Text(item[keyPath: path].localizedDate(dateStyle: .short, timeStyle: .short))
        }
    }

    func numColumn<T: BinaryInteger>(named key: LocalizedStringKey, path: KeyPath<TableElement, T>) -> TableColumn<TableElement, KeyPathComparator<TableElement>, Text, Text> {
        TableColumn(key, value: path, comparator: NumericComparator()) { item in
            Text(item[keyPath: path].localizedNumber())
        }
    }

    func boolColumn(named key: LocalizedStringKey, path: KeyPath<TableElement, Bool>) -> TableColumn<TableElement, KeyPathComparator<TableElement>, Toggle<EmptyView>, Text> {
        TableColumn(key, value: path, comparator: BoolComparator()) { item in
            Toggle(isOn: .constant(item[keyPath: path])) { EmptyView () }
        }
    }

    /// Non-optional string column
    func strColumn(named key: LocalizedStringKey, path: KeyPath<TableElement, String>) -> TableColumn<TableElement, KeyPathComparator<TableElement>, Text, Text> {
        TableColumn(key, value: path, comparator: .localizedStandard) { item in
            Text(item[keyPath: path])
        }
    }

    func ostrColumn(named key: LocalizedStringKey, path: KeyPath<TableElement, String?>) -> TableColumn<TableElement, KeyPathComparator<TableElement>, Text, Text> {
        TableColumn(key, value: path, comparator: StringComparator()) { item in
            Text(item[keyPath: path] ?? "")
        }
    }

    func onumColumn<T: BinaryInteger>(named key: LocalizedStringKey, path: KeyPath<TableElement, T?>) -> TableColumn<TableElement, KeyPathComparator<TableElement>, Text, Text> {
        TableColumn(key, value: path, comparator: NumComparator()) { item in
            Text(item[keyPath: path]?.localizedNumber() ?? "")
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


//@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
//extension SortComparator where Self == Int?.Comparator {
//    public static var optionalNumeric: Int.Comparator {
//
//    }
//}

