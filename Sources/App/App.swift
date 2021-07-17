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

/// The manager for the current app fair
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
open class AppEnv: AppEnvironmentObject {
    @AppStorage("someToggle") open var someToggle = false
    @Published open var searchText: String = ""
}


@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public extension AppScene {
    /// The body of your scene must exist in an extension of `AppScene`
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
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
