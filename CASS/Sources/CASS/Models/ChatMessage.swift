import Foundation

public struct ChatMessage: Codable, Identifiable {
    public let id: UUID
    public let content: String
    public let isFromUser: Bool
    public let timestamp: Date
    
    public init(id: UUID = UUID(), content: String, isFromUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
    }
}