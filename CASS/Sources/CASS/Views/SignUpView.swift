import SwiftUI

@available(macOS 14.0, *)
public struct SignUpView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @State private var username = ""
    @State private var name = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Create Account")) {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                    
                    TextField("Full Name", text: $name)
                        .textContentType(.name)
                }
                
                Section {
                    Button("Sign Up") {
                        signUp()
                    }
                    .disabled(username.isEmpty || name.isEmpty)
                }
            }
            .navigationTitle("Welcome to CASS")
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func signUp() {
        Task {
            do {
                try await userViewModel.signUp(username: username, name: name)
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

@available(macOS 14.0, *)
#Preview {
    SignUpView()
        .environmentObject(UserViewModel())
} 