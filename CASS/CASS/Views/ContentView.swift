import SwiftUI

struct ContentView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    
    var body: some View {
        ChatView(viewModel: chatViewModel)
            .sheet(isPresented: $chatViewModel.showingProfileSetup) {
                ProfileSetupView(viewModel: chatViewModel)
            }
    }
}

#Preview {
    ContentView()
} 