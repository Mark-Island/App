import Swift
import SwiftUI
import FairApp

#if os(macOS)
/// A container for a Table
@available(macOS 12.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
protocol ItemTableView : TableRowContent & TableColumnContent where TableColumnSortComparator == KeyPathComparator<TableRowValue> {

    /// The items that this table holds
    var items: [TableRowValue] { get nonmutating set }

    /// The current selection, if any
    var selection: TableRowValue.ID? { get nonmutating set }

    /// The current sort orders
    var sortOrder: [KeyPathComparator<TableRowValue>] { get nonmutating set }

    /// Filters the rows based on the current search term
    func filterRows(_ items: [TableRowValue]) -> [TableRowValue]

    /// The table view of the data
    var tableView: Table<TableRowValue, Self, Self> { get }
}

@available(macOS 12.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension ItemTableView {
    /// By default no searching is performed
    func filterRows(_ items: [TableRowValue]) -> [TableRowValue] {
        return items
    }
}

//@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
//extension ItemTableView where TableRowBody.TableRowValue == TableColumnBody.TableRowValue, TableColumnBody.TableColumnSortComparator == TableColumnSortComparator, TableColumnSortComparator.Compared == TableRowBody.TableRowValue, TableRowValue == TableColumnBody.TableRowValue {
//    /// The table view onto this data
//    var tableView: Table<TableRowValue, Self, Self> {
//        let table = Table(selection: Binding(get: { selection }, set: { selection = $0 }), sortOrder: Binding(get: { sortOrder }, set: { sortOrder = $0 }), columns: { self }, rows: { self })
//
//        return table
//     }
//}

@available(macOS 12.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension ItemTableView {

    func dateColumn(named key: LocalizedStringKey, path: KeyPath<TableRowValue, Date>) -> TableColumn<TableRowValue, KeyPathComparator<TableRowValue>, Text, Text> {
        TableColumn(key, value: path, comparator: DateComparator()) { item in
            Text(item[keyPath: path].localizedDate(dateStyle: .short, timeStyle: .short))
        }
    }

    func numColumn<T: BinaryInteger>(named key: LocalizedStringKey, path: KeyPath<TableRowValue, T>) -> TableColumn<TableRowValue, KeyPathComparator<TableRowValue>, Text, Text> {
        TableColumn(key, value: path, comparator: NumericComparator()) { item in
            Text(item[keyPath: path].localizedNumber())
        }
    }

    func boolColumn(named key: LocalizedStringKey, path: KeyPath<TableRowValue, Bool>) -> TableColumn<TableRowValue, KeyPathComparator<TableRowValue>, Toggle<EmptyView>, Text> {
        TableColumn(key, value: path, comparator: BoolComparator()) { item in
            Toggle(isOn: .constant(item[keyPath: path])) { EmptyView () }
        }
    }

    /// Non-optional string column
    func strColumn(named key: LocalizedStringKey, path: KeyPath<TableRowValue, String>) -> TableColumn<TableRowValue, KeyPathComparator<TableRowValue>, Text, Text> {
        TableColumn(key, value: path, comparator: .localizedStandard) { item in
            Text(item[keyPath: path])
        }
    }

    func ostrColumn(named key: LocalizedStringKey, path: KeyPath<TableRowValue, String?>) -> TableColumn<TableRowValue, KeyPathComparator<TableRowValue>, Text, Text> {
        TableColumn(key, value: path, comparator: StringComparator()) { item in
            Text(item[keyPath: path] ?? "")
        }
    }

    func onumColumn<T: BinaryInteger>(named key: LocalizedStringKey, path: KeyPath<TableRowValue, T?>) -> TableColumn<TableRowValue, KeyPathComparator<TableRowValue>, Text, Text> {
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


@available(macOS 12.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ActionsTableView : View, ItemTableView {
    @EnvironmentObject var appEnv: AppEnv
    typealias TableRowValue = FairHub.WorkflowRun
    @State var selection: TableRowValue.ID? = nil
    @State var sortOrder = [KeyPathComparator(\TableRowValue.created_at)]
    @State var searchText: String = ""
    @State var items: [TableRowValue] = []

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

    //var tableColumnBody: some TableColumnContent {
    var tableColumnBody: Group<TupleTableColumnContent<ActionsTableView.TableRowValue, KeyPathComparator<ActionsTableView.TableRowValue>, (TableColumn<ActionsTableView.TableRowValue, KeyPathComparator<ActionsTableView.TableRowValue>, URLImage?, Text>, TableColumn<ActionsTableView.TableRowValue, KeyPathComparator<ActionsTableView.TableRowValue>, Text, Text>, TableColumn<ActionsTableView.TableRowValue, KeyPathComparator<ActionsTableView.TableRowValue>, Text, Text>, TableColumn<ActionsTableView.TableRowValue, KeyPathComparator<ActionsTableView.TableRowValue>, Text, Text>, TableColumn<ActionsTableView.TableRowValue, KeyPathComparator<ActionsTableView.TableRowValue>, Text, Text>, TableColumn<ActionsTableView.TableRowValue, KeyPathComparator<ActionsTableView.TableRowValue>, Text, Text>, TableColumn<ActionsTableView.TableRowValue, KeyPathComparator<ActionsTableView.TableRowValue>, Text, Text>, TableColumn<ActionsTableView.TableRowValue, KeyPathComparator<ActionsTableView.TableRowValue>, Text, Text>, TableColumn<ActionsTableView.TableRowValue, KeyPathComparator<ActionsTableView.TableRowValue>, Text, Text>)>> {

        let imageColumn = TableColumn("", value: \TableRowValue.head_repository?.owner.avatar_url, comparator: StringComparator()) { item in
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
        let hashColumn = TableColumn("Hash", value: \TableRowValue.head_sha) { item in
            Text(item.head_sha).font(Font.system(.body, design: .monospaced))
        }

        let tableColumnBody = Group {
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

        return tableColumnBody
    }

    var tableRowBody: some TableRowContent {
        ForEach(filterRows(self.items)) { item in
            TableRow(item)
                //.itemProvider { items.itemProvider }
        }
    }

    var tableView: Table<TableRowValue, Self, Self> {
        Table(selection: Binding(get: { selection }, set: { selection = $0 }), sortOrder: Binding(get: { sortOrder }, set: { sortOrder = $0 }), columns: { self }, rows: { self })
    }

    var table: some View {
        tableView
            .tableStyle(.inset(alternatesRowBackgrounds: true))
            .font(Font.body.monospacedDigit())
            .onChange(of: sortOrder) {
                self.items.sort(using: $0)
            }
            .focusedSceneValue(\.selection, .constant(itemSelection))
            .focusedSceneValue(\.reloadCommand, .constant({ await fetchRuns(cache: .reloadIgnoringLocalAndRemoteCacheData) }))
            .searchable(text: $searchText)
    }

    /// The currently selected item
    var itemSelection: Selection? {
        guard let item = items.first(where: { $0.id == selection }) else {
            return nil
        }

        return Selection.run(item)
    }

    func filterRows(_ items: [TableRowValue]) -> [TableRowValue] {
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

@available(macOS 12.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ReleasesTableView : View, ItemTableView {
    @EnvironmentObject var appEnv: AppEnv
    typealias TableRowValue = AppRelease
    @State var selection: TableRowValue.ID? = nil
    @State var sortOrder = [KeyPathComparator(\TableRowValue.release.published_at)]
    @State var searchText: String = ""
    @State var items: [TableRowValue] = []

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

    //var tableColumnBody: some TableColumnContent {
    var tableColumnBody: Group<TupleTableColumnContent<AppRelease, KeyPathComparator<AppRelease>, (Group<TupleTableColumnContent<AppRelease, KeyPathComparator<AppRelease>, (TableColumn<AppRelease, KeyPathComparator<AppRelease>, Optional<URLImage>, Text>, TableColumn<AppRelease, KeyPathComparator<AppRelease>, Text, Text>, TableColumn<AppRelease, KeyPathComparator<AppRelease>, Text, Text>, TableColumn<AppRelease, KeyPathComparator<AppRelease>, Optional<Link<Text>>, Text>, TableColumn<AppRelease, KeyPathComparator<AppRelease>, Text, Text>, TableColumn<AppRelease, KeyPathComparator<AppRelease>, Text, Text>, TableColumn<AppRelease, KeyPathComparator<AppRelease>, Text, Text>)>>, Group<TupleTableColumnContent<AppRelease, KeyPathComparator<AppRelease>, (TableColumn<AppRelease, KeyPathComparator<AppRelease>, Text, Text>, TableColumn<AppRelease, KeyPathComparator<AppRelease>, Text, Text>, TableColumn<AppRelease, KeyPathComparator<AppRelease>, Text, Text>, TableColumn<AppRelease, KeyPathComparator<AppRelease>, Text, Text>)>>, Group<TupleTableColumnContent<AppRelease, KeyPathComparator<AppRelease>, (TableColumn<AppRelease, KeyPathComparator<AppRelease>, Toggle<EmptyView>, Text>, TableColumn<AppRelease, KeyPathComparator<AppRelease>, Toggle<EmptyView>, Text>, TableColumn<AppRelease, KeyPathComparator<AppRelease>, Text, Text>, TableColumn<AppRelease, KeyPathComparator<AppRelease>, Text, Text>)>>)>> {
        let imageColumn: TableColumn<TableRowValue, KeyPathComparator<TableRowValue>, URLImage?, Text> = TableColumn("", value: \TableRowValue.repository.owner.avatar_url, comparator: StringComparator()) { item in
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

        let sizeColumn = TableColumn("Size", value: \TableRowValue.release.assets.first?.size, comparator: OptionalNumericComparator()) { item in
            Text(item.release.assets.first?.size.localizedByteCount(countStyle: .file) ?? "N/A")
        }

        let draftColumn = boolColumn(named: "Draft", path: \.release.draft)
        let preReleaseColumn = boolColumn(named: "Pre-Release", path: \.release.prerelease)

        let downloadColumn = TableColumn("Download", value: \TableRowValue.release.assets.first?.browser_download_url.lastPathComponent, comparator: StringComparator()) { item in
            //Text(item.assets.first?.state ?? "N/A")
            //Toggle(isOn: .constant(item.draft)) { EmptyView () }
            if let asset = item.release.assets.first {
                Link("Download \(asset.size.localizedByteCount(countStyle: .file))", destination: asset.browser_download_url)
            }
        }
        let tagColumn = TableColumn("Tag", value: \TableRowValue.release.tag_name)
        let infoColumn = TableColumn("Info", value: \TableRowValue.release.body) { item in
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

        let tableColumnBody = Group {
            // these need to be broken up to help the typechecker solve it in a reasonable amount of time
            columnGroup1
            columnGroup2
            columnGroup3
        }

        return tableColumnBody
    }

    var tableRowBody: some TableRowContent {
        ForEach(filterRows(self.items)) { item in
            TableRow(item)
                //.itemProvider { items.itemProvider }
        }
    }

    var tableView: Table<TableRowValue, Self, Self> {
        Table(selection: Binding(get: { selection }, set: { selection = $0 }), sortOrder: Binding(get: { sortOrder }, set: { sortOrder = $0 }), columns: { self }, rows: { self })
    }

    var table: some View {
        tableView
            .tableStyle(.inset(alternatesRowBackgrounds: false))
            .font(Font.body.monospacedDigit())
            .onChange(of: sortOrder) {
                self.items.sort(using: $0)
            }
            .focusedSceneValue(\.selection, .constant(itemSelection))
            .focusedSceneValue(\.reloadCommand, .constant({ await fetchApps(cache: .reloadIgnoringLocalAndRemoteCacheData) }))
            .searchable(text: $searchText)
    }

    /// The currently selected item
    var itemSelection: Selection? {
        guard let item = items.first(where: { $0.id == selection }) else {
            return nil
        }

        return Selection.app(item)
    }

    func filterRows(_ items: [TableRowValue]) -> [TableRowValue] {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? items
        : items.filter { item in
            item.repository.name.localizedCaseInsensitiveContains(searchText) == true
            || item.repository.owner.login.localizedCaseInsensitiveContains(searchText) == true
        }
    }
}

#endif // os(macOS)

