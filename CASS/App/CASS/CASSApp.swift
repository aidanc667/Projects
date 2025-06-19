import SwiftUI
import CASS

@main
struct CASSApp: App {
    @StateObject private var userViewModel = UserViewModel()
    
    var body: some Scene {
        WindowGroup {
            if userViewModel.isAuthenticated {
                ContentView()
                    .environmentObject(userViewModel)
            } else {
                SignUpView()
                    .environmentObject(userViewModel)
            }
        }
    }
} 