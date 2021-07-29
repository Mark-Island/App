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

@available(macOS 12.0, iOS 15.0, *)
public extension AppContainer {
    /// The body of your scene is provided by `AppContainer.scene`
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        WindowGroup {
            ContentView().environmentObject(store)
        }
        .commands {
            TextEditingCommands()
        }
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

#if canImport(AppKit)
typealias SplitView = HSplitView
#else
typealias SplitView = HStack
#endif

@available(macOS 12.0, iOS 15.0, *)
public struct ContentView: View {
    @EnvironmentObject var store: Store
    @State var md = ""

    public var body: some View {
        SplitView {
            ZStack {
                TextEditor(text: $md)
                if md.isEmpty {
                    Label("Enter Markdown Here", systemImage: "arrow.up.circle.fill")
                        .font(.title)
                }
            }

            ZStack {
                ScrollView {
                    Text(parse())
                        .frame(maxWidth: .infinity)
                }
                if md.isEmpty {
                    Text("Markdown Rendered Here")
                        .font(.title)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .font(Font.system(size: 18, weight: .thin, design: .monospaced))
    }

    func parse() -> AttributedString {
        let kp = \AttributeScopes.swiftUI
        let options = AttributedString.MarkdownParsingOptions(allowsExtendedAttributes: true, interpretedSyntax: .inlineOnlyPreservingWhitespace, failurePolicy: .returnPartiallyParsedIfPossible, languageCode: nil)
        let baseURL: URL? = nil

        let txt: AttributedString
        do {
            txt = try AttributedString(markdown: md, including: kp, options: options, baseURL: baseURL)
        } catch {
            txt = AttributedString("Error: \(error)")
        }

        return txt
    }
}

@available(macOS 12.0, iOS 15.0, *)
public struct AppSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        EmptyView()
    }
}

