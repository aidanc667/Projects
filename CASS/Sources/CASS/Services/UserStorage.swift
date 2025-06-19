import Foundation
import KeychainAccess

public class UserStorage {
    private let defaults = UserDefaults.standard
    private let userKey = "com.example.CASS.currentUser"
    private let keychain = Keychain(service: "com.example.CASS")
    
    private enum Keys {
        static let currentUser = "currentUser"
        static let isAuthenticated = "isAuthenticated"
        static let credentials = "userCredentials"
    }
    
    public init() {}
    
    // MARK: - User Data
    
    public func saveUser(_ user: User) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(user)
        defaults.set(data, forKey: userKey)
    }
    
    public func loadUser() -> User? {
        guard let data = defaults.data(forKey: userKey) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(User.self, from: data)
    }
    
    public func clearUser() {
        defaults.removeObject(forKey: userKey)
    }
    
    public func isAuthenticated() -> Bool {
        return defaults.bool(forKey: Keys.isAuthenticated)
    }
    
    // MARK: - Credentials
    
    public func saveCredentials(email: String, password: String) {
        let credentials = ["email": email, "password": password]
        if let encoded = try? JSONEncoder().encode(credentials) {
            try? keychain.set(encoded, key: Keys.credentials)
        }
    }
    
    public func loadCredentials() -> (email: String, password: String)? {
        guard let data = try? keychain.getData(Keys.credentials),
              let credentials = try? JSONDecoder().decode([String: String].self, from: data) else {
            return nil
        }
        guard let email = credentials["email"],
              let password = credentials["password"] else {
            return nil
        }
        return (email, password)
    }
    
    // MARK: - Clear Data
    
    public func clearAllData() {
        defaults.removeObject(forKey: userKey)
        defaults.set(false, forKey: Keys.isAuthenticated)
        try? keychain.remove(Keys.credentials)
    }
} 