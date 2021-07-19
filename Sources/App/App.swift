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
    /// The body of your scene is provided by `AppContainer.scene`
    @SceneBuilder var rootScene: some SwiftUI.Scene {
        WindowGroup {
            ContentView()
        }
    }

    /// The app-wide settings view
    @ViewBuilder var settingsView : some SwiftUI.View {
        AppSettingsView().environmentObject(appEnv)
    }
}

/// The shared app environment
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
@MainActor public final class AppEnv: AppEnvironmentObject {
    @AppStorage("someToggle") public var someToggle = false
}


@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct ContentView: View {
    @EnvironmentObject var appEnv: AppEnv

    public var body: some View {
        Text("Welcome to Fair Ground!")
            .font(.largeTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct AppSettingsView : View {
    @EnvironmentObject var appEnv: AppEnv

    public var body: some View {
        EmptyView()
    }
}
