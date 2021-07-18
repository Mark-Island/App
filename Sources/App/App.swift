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

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
@main public struct AppScene : FairApp.FairScene {
    @ObservedObject public var appEnv = AppEnv()
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
                .task {
                    await appEnv.windowAppeared()
                }
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

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public typealias AppEnv = FairManager

/// A released app
public struct AppRelease : Hashable, Identifiable {
    let repo: FairHub.RepositoryInfo
    let rel: FairHub.ReleaseInfo

    public var id: Int64 { rel.id }
}

/// The current selected instance, which can either be a release or a workflow run
enum Selection {
    case app(AppRelease)
    case run(FairHub.WorkflowRun)
}

/// The manager for the current app fair
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
@MainActor public final class FairManager: AppEnvironmentObject {
    @AppStorage("hubHost") var hubHost = "https://api.github.com"
    @AppStorage("hubToken") var hubToken = ""
    @AppStorage("hubOrg") var hubOrg = "appfair"
    @AppStorage("hubRepo") var hubRepo = "App"

    @Published var errors: [(AppFailure?, Error)] = []
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct AppFairCommands: Commands {
    @FocusedBinding(\.selection) private var selection: Selection??

    var body: some Commands {

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
            switch selection {
            case .app(let app):
                Button("Reload Apps") {
                    let start = CFAbsoluteTimeGetCurrent()
                    Task {
                        //await appEnv.loadResults(cache: .reloadIgnoringLocalAndRemoteCacheData)
                        let end = CFAbsoluteTimeGetCurrent()
                        print("reload apps:", end - start)
                    }
                }
                .keyboardShortcut("R")
            case .run(let run):
                Button("Reload Runs") {
                    let start = CFAbsoluteTimeGetCurrent()
                    Task {
                        //await appEnv.loadResults(cache: .reloadIgnoringLocalAndRemoteCacheData)
                        let end = CFAbsoluteTimeGetCurrent()
                        print("reload runs:", end - start)
                    }
                }
                .keyboardShortcut("R")
            case .none:
                EmptyView()
            case .some(.none):
                EmptyView()
            }

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
        let fks = Dictionary(grouping: forks, by: \.owner.login)
        var rels: [AppRelease] = []
        for release in releases {
            if let fork = fks[release.tag_name]?.first {
                rels.append(AppRelease(repo: fork, rel: release))
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

    #warning("Not working")
    var body : some View {
        Form {
            GroupBox("Release") {
                TextField("Name", text: .constant(app.rel.name))
            }

            GroupBox("Repository") {
                TextField("Organization", text: .constant(app.repo.name))
                TextField("Owner", text: .constant(app.repo.owner.login))
                TextField("Type", text: .constant(app.repo.owner.type))
                //TextField("ID", text: .constant(app.repo.owner.id))
            }
        }
        .padding()
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct RunInfoView : Equatable, View {
    let run: FairHub.WorkflowRun

    #warning("Not working")
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
//    var garden: Binding<Garden>? {
//        get { self[FocusedGardenKey.self] }
//        set { self[FocusedGardenKey.self] = newValue }
//    }

    var selection: Binding<Selection?>? {
        get { self[FocusedSelection.self] }
        set { self[FocusedSelection.self] = newValue }
    }

//    private struct FocusedGardenKey: FocusedValueKey {
//        typealias Value = Binding<Selection?>
//    }

    private struct FocusedSelection: FocusedValueKey {
        typealias Value = Binding<Selection?>
    }
}
//.focusedSceneValue(\.garden, $garden)


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
    @EnvironmentObject var fair: FairManager
    enum ViewMode: String, CaseIterable, Identifiable {
        var id: Self { self }
        case table
        case gallery
    }

    @SceneStorage("viewMode") private var mode: ViewMode = .table

    var item: FairManager.SidebarItem? = nil

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
//        .focusedSceneValue(\.garden, $garden)
//        .focusedSceneValue(\.selection, $selection)
        .toolbar {
            DisplayModePicker(mode: $mode)
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
//        .refreshable {
//            await fair.loadResults(cache: .reloadRevalidatingCacheData)
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
struct ActionsTableView : View, TableColumnator {
    typealias TableItemRoot = FairHub.WorkflowRun
    @EnvironmentObject var fair: FairManager
    @State var selection: TableItemRoot.ID? = nil
    @State private var sortOrder = [KeyPathComparator(\TableItemRoot.created_at)]
    @State var searchText: String = ""
    @State var items: [FairHub.WorkflowRun] = []

    var body: some View {
        table
            .task { await fetchRuns() }
    }

    func fetchRuns(cache: URLRequest.CachePolicy? = nil) async {
        do {
            self.items = try await fair.fetchRuns(cache: cache).workflow_runs
        } catch {
            fair.errors.append((nil, error))
        }
    }

    var table: some View {
        let imageColumn = TableColumn("", value: \TableItemRoot.head_repository?.owner.avatar_url, comparator: StringComparator()) { item in
            if let avatar_url = item.head_repository?.owner.avatar_url, let url = URL(string: avatar_url) {
                URLImage(url: url, resizable: .fit)
            }
        }
        .width(50)

        let ownerColumn = ostrColumn(named: "Owner", path: \.head_repository?.owner.login)
        let statusColumn = ostrColumn(named: "Status", path: \.status?.rawValue)
        let conclusionColumn = ostrColumn(named: "Conclusion", path: \.conclusion?.rawValue)
        let runColumn = numColumn(named: "Run #", path: \.run_number)
        let authorColumn = strColumn(named: "Author", path: \.head_commit.author.name)
        let createdColumn = dateColumn(named: "Created", path: \.created_at)
        let updatedColumn = dateColumn(named: "Updated", path: \.updated_at)
        let hashColumn = TableColumn("Hash", value: \TableItemRoot.head_sha) { item in
            Text(item.head_sha).font(Font.system(.body, design: .monospaced))
        }

        return Table(selection: $selection, sortOrder: $sortOrder) {
            Group {
                imageColumn
                ownerColumn
                statusColumn
                conclusionColumn
                runColumn
                authorColumn
                createdColumn
                updatedColumn
                hashColumn.width(ideal: 350) // about the right length to fit a SHA-1 hash
            }
        } rows: {
            ForEach(search(self.items)) { items in
                TableRow(items)
                    //.itemProvider { items.itemProvider }
            }
//            .onInsert(of: [Item.draggableType]) { index, providers in
//                Item.fromItemProviders(providers) { items in
//                    item.items.insert(contentsOf: items, at: index)
//                }
//            }
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .font(Font.body.monospacedDigit())
        .onChange(of: sortOrder) {
            self.items.sort(using: $0)
        }
        .focusedSceneValue(\.selection, .constant(itemSelection))
        .searchable(text: $searchText)
    }

    /// The currently selected item
    var itemSelection: Selection? {
        guard let item = items.first(where: { $0.id == selection }) else {
            return nil
        }

        return Selection.run(item)
    }

    private func search(_ items: [TableItemRoot]) -> [TableItemRoot] {
        searchText.isEmpty ? items
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
struct ReleasesTableView : View, TableColumnator {
    typealias TableItemRoot = AppRelease
    @EnvironmentObject var fair: FairManager
    @State var selection: AppRelease.ID? = nil
    @State private var sortOrder = [KeyPathComparator(\AppRelease.rel.created_at)]
    @State var items: [TableItemRoot] = []
    @State var searchText: String = ""

    var body: some View {
        table
            .task { await fetchApps() }
    }

    func fetchApps(cache: URLRequest.CachePolicy? = nil) async {
        async let rels = fair.fetchReleases(cache: cache)
        async let forks = fair.fetchForks(cache: cache)
        do {
            self.items = try await fair.match(rels, forks)
        } catch {
            Task { // otherwise warnings about accessing off of the main thread
                fair.errors.append((nil, error))
            }
        }
    }

    var table: some View {
        Table(selection: $selection, sortOrder: $sortOrder) {
            Group {
                TableColumn("", value: \AppRelease.repo.owner.avatar_url, comparator: StringComparator()) { item in
                    if let avatar_url = item.repo.owner.avatar_url, let url = URL(string: avatar_url) {
                        URLImage(url: url, resizable: .fit)
                    }
                }
                .width(50)
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

                TableColumn("Size", value: \AppRelease.rel.assets.first?.size, comparator: OptionalNumericComparator()) { item in
                    Text(item.rel.assets.first?.size.localizedByteCount(countStyle: .file) ?? "N/A")
                }
            }

            Group {
                boolColumn(named: "Draft", path: \.rel.draft)
                boolColumn(named: "Pre-Release", path: \.rel.prerelease)
            }

            Group {
                TableColumn("Download", value: \AppRelease.rel.assets.first?.browser_download_url.lastPathComponent, comparator: StringComparator()) { item in
                    //Text(item.assets.first?.state ?? "N/A")
                    //Toggle(isOn: .constant(item.draft)) { EmptyView () }
                    if let asset = item.rel.assets.first {
                        Link("Download \(asset.size.localizedByteCount(countStyle: .file))", destination: asset.browser_download_url)
                    }
                }
                TableColumn("Tag", value: \AppRelease.rel.tag_name)
                TableColumn("Info", value: \AppRelease.rel.body) { item in
                    Text((try? item.rel.body.atx()) ?? "No info")
                }
            }
        } rows: {
            ForEach(search(self.items)) { items in
                TableRow(items)
                    //.itemProvider { items.itemProvider }
            }
//            .onInsert(of: [Item.draggableType]) { index, providers in
//                Item.fromItemProviders(providers) { items in
//                    item.items.insert(contentsOf: items, at: index)
//                }
//            }
        }
        .tableStyle(.inset(alternatesRowBackgrounds: false))
        .font(Font.body.monospacedDigit())
        .onChange(of: sortOrder) {
            self.items.sort(using: $0)
        }
        .focusedSceneValue(\.selection, .constant(itemSelection))
        .searchable(text: $searchText)
    }

    /// The currently selected item
    var itemSelection: Selection? {
        guard let item = items.first(where: { $0.id == selection }) else {
            return nil
        }

        return Selection.app(item)
    }

    private func search(_ items: [TableItemRoot]) -> [TableItemRoot] {
        searchText.isEmpty ? items
        : items.filter { item in
            item.repo.name.localizedCaseInsensitiveContains(searchText) == true
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
protocol TableColumnator {
    associatedtype TableItemRoot : Identifiable

    /// The items that this table holds
    var items: [TableItemRoot] { get nonmutating set }

    /// The current selection, if any
    var selection: TableItemRoot.ID? { get nonmutating set }
}


@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension TableColumnator {

    func dateColumn(named key: LocalizedStringKey, path: KeyPath<TableItemRoot, Date>) -> TableColumn<TableItemRoot, KeyPathComparator<TableItemRoot>, Text, Text> {
        TableColumn(key, value: path, comparator: DateComparator()) { item in
            Text(item[keyPath: path].localizedDate(dateStyle: .short, timeStyle: .short))
        }
    }

    func numColumn<T: BinaryInteger>(named key: LocalizedStringKey, path: KeyPath<TableItemRoot, T>) -> TableColumn<TableItemRoot, KeyPathComparator<TableItemRoot>, Text, Text> {
        TableColumn(key, value: path, comparator: NumericComparator()) { item in
            Text(item[keyPath: path].localizedNumber())
        }
    }

    func boolColumn(named key: LocalizedStringKey, path: KeyPath<TableItemRoot, Bool>) -> TableColumn<TableItemRoot, KeyPathComparator<TableItemRoot>, Toggle<EmptyView>, Text> {
        TableColumn(key, value: path, comparator: BoolComparator()) { item in
            Toggle(isOn: .constant(item[keyPath: path])) { EmptyView () }
        }
    }

    /// Non-optional string column
    func strColumn(named key: LocalizedStringKey, path: KeyPath<TableItemRoot, String>) -> TableColumn<TableItemRoot, KeyPathComparator<TableItemRoot>, Text, Text> {
        TableColumn(key, value: path, comparator: .localizedStandard) { item in
            Text(item[keyPath: path])
        }
    }

    func ostrColumn(named key: LocalizedStringKey, path: KeyPath<TableItemRoot, String?>) -> TableColumn<TableItemRoot, KeyPathComparator<TableItemRoot>, Text, Text> {
        TableColumn(key, value: path, comparator: StringComparator()) { item in
            Text(item[keyPath: path] ?? "")
        }
    }

    func onumColumn<T: BinaryInteger>(named key: LocalizedStringKey, path: KeyPath<TableItemRoot, T?>) -> TableColumn<TableItemRoot, KeyPathComparator<TableItemRoot>, Text, Text> {
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
