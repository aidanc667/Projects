import Foundation
import SwiftUI
import KeychainAccess

@MainActor
public class UserViewModel: ObservableObject {
    @Published public private(set) var currentUser: User?
    @Published public private(set) var isAuthenticated = false
    @Published public var errorMessage: String?
    
    private let userStorage: UserStorage
    private let keychain = Keychain(service: "com.example.CASS")
    
    public init(userStorage: UserStorage = UserStorage()) {
        self.userStorage = userStorage
        loadSavedUser()
    }
    
    private func loadSavedUser() {
        if let savedUser = userStorage.loadUser() {
            self.currentUser = savedUser
            self.isAuthenticated = true
        }
    }
    
    public func signUp(username: String, name: String) async throws {
        let user = User(username: username, name: name)
        try userStorage.saveUser(user)
        self.currentUser = user
        self.isAuthenticated = true
    }
    
    public func signIn(username: String) async throws {
        if let savedUser = userStorage.loadUser(), savedUser.username == username {
            self.currentUser = savedUser
            self.isAuthenticated = true
        } else {
            throw AuthError.invalidCredentials
        }
    }
    
    public func signOut() {
        userStorage.clearUser()
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    public func updateInterests(_ interests: [String]) {
        guard var user = currentUser else { return }
        user.interests = interests
        try? userStorage.saveUser(user)
        self.currentUser = user
    }
    
    public func updatePreferences(_ preferences: [String: String]) {
        guard var user = currentUser else { return }
        user.preferences = preferences
        try? userStorage.saveUser(user)
        self.currentUser = user
    }
}

public enum AuthError: Error {
    case invalidCredentials
}