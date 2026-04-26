import SwiftUI

@main
struct AffinityApp: App {
    @StateObject private var session = UserSession()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
        }
    }
}
