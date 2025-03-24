import SwiftUI
import Firebase

@main
struct Soar_betaApp: App {
    @StateObject var authViewModel = AuthViewModel()
    @StateObject var tabSelection = TabSelection()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(tabSelection)
        }
    }
}
