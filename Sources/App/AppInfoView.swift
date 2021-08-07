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
struct AppInfoView : Equatable, View {
    let app: AppRelease

    var body : some View {
        VStack {
            HStack {
                URLImage(url: app.repository.owner.appIconURL, resizable: .fit)
                    .frame(width: 94)
                VStack {
                    Text(app.repository.owner.appName).font(.largeTitle)
                    Text("Subtitle").font(.title)
                }

                Spacer()
            }

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


// Previews broken in Xcode Version 13.0 beta 4 (13A5201i)
//struct AppInfoView_Previews : PreviewProvider {
//    static var previews: some View {
//        Text("Hello")
////        AppInfoView(app: AppRelease(repository: FairHub.RepositoryInfo(, release: FairHub.ReleaseInfo())
//    }
//}
