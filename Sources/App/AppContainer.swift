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

// The entry point to creating your app is the `AppContainer` type,
// which is a stateless enum declared in `AppMain.swift` and may not be changed.
// 
// App customization is done via extensions in `AppContainer.swift`,
// which enables customization of the root scene, app settings, and
// other features of the app.

@available(macOS 12.0, iOS 15.0, *)
public extension AppContainer {
    /// The body of your scene is provided by `AppContainer.scene`
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        WindowGroup {
            ContentView().environmentObject(store)
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


@available(macOS 12.0, iOS 15.0, *)
public struct ContentView: View {
    @EnvironmentObject var store: Store
    let appName = Bundle.main.bundleDisplayName ?? Bundle.main.bundleName ?? "Fair App"
    let appID = Bundle.main.bundleIdentifier ?? "app.App-Org"
    let issuesURL = URL.fairHubURL("issues")!
    let discussionsURL = URL.fairHubURL("discussions")!

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Welcome \(appName)", bundle: .module)
                .font(.largeTitle)
                .multilineTextAlignment(.center)

            Text("App Checklist:", bundle: .module)
                .font(.title)
                .multilineTextAlignment(.center)

            Text("""
                1. Edit the *CFBundleName* in the `Info.plist`: \(appName)
                2. Edit the *CFBundleIdentifier* in the `Info.plist`: \(appID)
                3. Verify issues are enabled at: [\(issuesURL.absoluteString)](\(issuesURL.absoluteString))
                4. Verify discussions are enabled at: [\(discussionsURL.absoluteString)](\(discussionsURL.absoluteString))
                """, bundle: .module)
                .font(.title2)

            Spacer()

            Text(verbatim: "[https://www.appfair.net](https://www.appfair.net)")
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .allowsTightening(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    }
}

@available(macOS 12.0, iOS 15.0, *)
public struct AppSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        EmptyView()
    }
}

