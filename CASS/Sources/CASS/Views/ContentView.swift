import SwiftUI

public struct ContentView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @State private var selectedTab = 0
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message")
                }
                .tag(0)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(1)
        }
    }
}

private struct ProfileView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @State private var interests: [String] = []
    @State private var newInterest = ""
    @State private var preferences: [String: String] = [:]
    @State private var newPreferenceKey = ""
    @State private var newPreferenceValue = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("User Information")) {
                    if let user = userViewModel.currentUser {
                        Text("Username: \(user.username)")
                        Text("Name: \(user.name)")
                    }
                }
                
                Section(header: Text("Interests")) {
                    ForEach(interests, id: \.self) { interest in
                        Text(interest)
                    }
                    
                    HStack {
                        TextField("New Interest", text: $newInterest)
                        Button("Add") {
                            if !newInterest.isEmpty {
                                interests.append(newInterest)
                                userViewModel.updateInterests(interests)
                                newInterest = ""
                            }
                        }
                    }
                }
                
                Section(header: Text("Preferences")) {
                    ForEach(Array(preferences.keys), id: \.self) { key in
                        if let value = preferences[key] {
                            HStack {
                                Text(key)
                                Spacer()
                                Text(value)
                            }
                        }
                    }
                    
                    VStack {
                        TextField("Key", text: $newPreferenceKey)
                        TextField("Value", text: $newPreferenceValue)
                        Button("Add Preference") {
                            if !newPreferenceKey.isEmpty && !newPreferenceValue.isEmpty {
                                preferences[newPreferenceKey] = newPreferenceValue
                                userViewModel.updatePreferences(preferences)
                                newPreferenceKey = ""
                                newPreferenceValue = ""
                            }
                        }
                    }
                }
                
                Section {
                    Button("Sign Out", role: .destructive) {
                        userViewModel.signOut()
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                if let user = userViewModel.currentUser {
                    interests = user.interests
                    preferences = user.preferences
                }
            }
        }
    }
}

#Preview {
    ContentView()
} 