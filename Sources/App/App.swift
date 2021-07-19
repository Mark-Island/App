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
@main public struct AppContainer : FairApp.FairContainer {
    @ObservedObject public var appEnv = AppEnv()
    public init() { }
    public static func main() throws { try launch() }
}

// Everything above this line must remain unmodified.

// Define your app in an extension of `AppContainer`

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public extension AppContainer {
    var settingsView : some View {
        AppSettingsView().environmentObject(appEnv)
    }

    var rootScene: some Scene {
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
            // ImportFromDevicesCommands() // unavailable in iOS

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

        var label: TintedLabel {
            switch self {
            case .popular:
                return TintedLabel(title: "Popular", systemName: "star", tint: Color.yellow)
            case .favorites:
                return TintedLabel(title: "Favorites", systemName: "pin", tint: Color.red)
            case .recent:
                return TintedLabel(title: "Recent", systemName: "flag", tint: Color.purple) // clock or bolt?
            case .category(let grouping):
                return grouping.label
            case .search(let term):
                return TintedLabel(title: "Search: \(term)", systemName: "magnifyingglass", tint: Color.gray)
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
            SidebarView().frame(minWidth: 160) // .controlSize(.large)
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

/// A label that tints its image
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct TintedLabel : View {
    public let title: LocalizedStringKey
    public let systemName: StaticString
    public let tint: Color

    public var body: some View {
        Label(title: { Text(title) }) {
//            Image(systemName: systemName.description)
//                .symbolVariant(.circle)
//                .symbolVariant(.fill)
//                .symbolVariant(.none)
//                .foregroundStyle(tint)
////                .foregroundStyle(.red, .white, .blue)
////                .listItemTint(ListItemTint.fixed(tint))

            Image(systemName: systemName.description)
                //.symbolRenderingMode(.palette)
                .symbolRenderingMode(.multicolor)
                //.symbolVariant(.circle)
                //.symbolVariant(.fill)
                .foregroundStyle(
                    .linearGradient(colors: [tint, .white], startPoint: .top, endPoint: .bottomTrailing),
                    .linearGradient(colors: [.green, .black], startPoint: .top, endPoint: .bottomTrailing),
                    .linearGradient(colors: [.blue, .black], startPoint: .top, endPoint: .bottomTrailing)
                )
                //.font(.title)

        }
    }
}

public extension AppCategory {
    /// The grouping for an app category
    enum Grouping : String, CaseIterable, Hashable {
        case create
        case research
        case communicate
        case entertain
        case live
        case game
        case work

        /// All the categories that belong to this grouping
        public var categories: [AppCategory] {
            AppCategory.allCases.filter({ $0.groupings.contains(self) })
        }

        @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
        public var label: TintedLabel {
            switch self {
            case .create:
                return TintedLabel(title: "Arts & Crafts", systemName: "paintpalette", tint: Color.cyan)
            case .research:
                return TintedLabel(title: "Knowledge", systemName: "book", tint: Color.green)
            case .communicate:
                return TintedLabel(title: "Communication", systemName: "envelope", tint: Color.pink)
            case .entertain:
                return TintedLabel(title: "Entertainment", systemName: "sparkles.tv", tint: Color.teal)
            case .live:
                return TintedLabel(title: "Lifestyle & Health", systemName: "house", tint: Color.mint)
            case .game:
                return TintedLabel(title: "Diversion", systemName: "circle.hexagongrid", tint: Color.yellow)
            case .work:
                return TintedLabel(title: "Work", systemName: "briefcase", tint: Color.brown)
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

        case .socialnetworking: return [.communicate]

        case .healthcarefitness: return [.live]
        case .lifestyle: return [.live]
        case .medical: return [.live]
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
        .toolbar(id: "SidebarView") {
            tool(.popular)
            tool(.favorites)
            tool(.recent)
            tool(.category(.entertain))
            tool(.category(.research))
            tool(.category(.create))
            tool(.category(.game))
            tool(.category(.live))
            tool(.category(.work))
        }
    }

    func item(_ item: AppEnv.SidebarItem) -> some View {
        NavigationLink(destination: AppsListView(item: item)) {
            item.label
                .badge(appEnv.badgeCount(for: item))
        }
    }

    func tool(_ item: AppEnv.SidebarItem) -> some CustomizableToolbarContent {
        ToolbarItem(id: item.id, placement: .automatic, showsByDefault: false) {
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
            if let img = try? UXImage(data: Data(contentsOf: url)) {
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
    var labelContent: (name: LocalizedStringKey, systemImage: String) {
        switch self {
        case .table:
            return ("Table", "tablecells")
        case .gallery:
            return ("Gallery", "square.grid.3x2.fill")
        }
    }

    var label: some View {
        Label(labelContent.name, systemImage: labelContent.systemImage)
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct AppsListView: View {
    @EnvironmentObject var appEnv: AppEnv
    @SceneStorage("viewMode") private var mode: ViewMode = .table

    /// Whether to display the items as a table or gallery
    enum ViewMode: String, CaseIterable, Identifiable {
        var id: Self { self }
        case table
        case gallery
    }

    var item: AppEnv.SidebarItem? = nil

    var body: some View {
        Group {
            #if os(macOS)
            if mode == .table {
                switch item {
                case .recent:
                    ActionsTableView()
                default:
                    ReleasesTableView()
                }
            } else {
                SampleImagesListView()
            }
            #else
            SampleImagesListView()
            #endif
        }
//        .padding()
//        .focusedSceneValue(\.selection, $selection)
        .toolbar {
            ToolbarItem(id: "DisplayModePicker", placement: .automatic, showsByDefault: true) {
                DisplayModePicker(mode: $mode)
            }
        }
        .navigationTitle(item?.label.title ?? "Apps")
    }
}


@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct SampleImagesListView: View {
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

