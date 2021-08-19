# This Is Your App

This project contains an [AppFair](https://www.appfair.net) app,
which is a free, native, and secure application distribution platform
for pure SwiftUI applications. 

To get started building your own app:

1. Create a new free GitHub Organization. 
   The organization name will uniquely identify your app and 
   consists of two short words separated by a single hyphen 
   two distinct sequences of 3-12 letters in the Latin alphabet. 
   For example: "Cookie-Time"
2. [Fork the appfair/App repository](https://github.com/appfair/App/fork) 
   into your new "App-Org" organization. An app-org can only contains 
   a single app that is named "App" (literally). 
   It must be publicly accessible at `github.com/App-Org/App.git`
3. Update your App settings: enable Issues and Discussions for 
   your `App-Org/App` fork. 
   Issues & Discussions are required to remain active to act as
   communication channels between the developer and end-users of the app. 
4. [Edit Info.plist](../../edit/main/Info.plist) and update 
   the `CFBundleName` to be "App Org" (the app name with a space) 
   and `CFBundleIdentifier` to be "app.App-Org".
5. [Edit Sources/App/AppContainer.swift](../../edit/main/Sources/App/AppContainer.swift) 
   and add some code to your app!
6. [Create a Pull Request](../../compare) with your changes, and submit 
   the PR to the base `/appfair/App/` repository. 
   The PR itself must remain open for as long as the app is to be available.
   Updating the PR is the mechanism for triggering 
   the [App Fair actions](https://github.com/appfair/App/actions) 
   that validates and builds your release and updates the App Fair catalog.

Your successful release build will shortly become available in 
the `App Fair` catalog browser application.

Download, share and enjoy!

