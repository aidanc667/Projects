import Foundation

public struct User: Codable, Identifiable {
    public let id: UUID
    public var username: String
    public var name: String
    public var interests: [String]
    public var preferences: [String: String]
    
    public init(id: UUID = UUID(), username: String, name: String, interests: [String] = [], preferences: [String: String] = [:]) {
        self.id = id
        self.username = username
        self.name = name
        self.interests = interests
        self.preferences = preferences
    }
}