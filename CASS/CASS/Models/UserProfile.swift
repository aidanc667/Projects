import Foundation

struct UserProfile: Codable {
    var id: UUID
    var name: String
    var interests: [String]
    var preferredTone: TonePreference
    var goals: [String]
    var lastInteractionDate: Date
    var chatHistory: [HistoryEntry]
    
    enum TonePreference: String, Codable {
        case professional
        case casual
        case friendly
        case direct
    }
    
    struct HistoryEntry: Codable, Identifiable {
        let id: UUID
        let timestamp: Date
        let query: String
        let response: String
        let topic: String
        
        init(query: String, response: String, topic: String) {
            self.id = UUID()
            self.timestamp = Date()
            self.query = query
            self.response = response
            self.topic = topic
        }
    }
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.interests = []
        self.preferredTone = .friendly
        self.goals = []
        self.lastInteractionDate = Date()
        self.chatHistory = []
    }
    
    mutating func addHistoryEntry(query: String, response: String, topic: String) {
        let entry = HistoryEntry(query: query, response: response, topic: topic)
        chatHistory.append(entry)
        lastInteractionDate = Date()
    }
    
    func getRecentTopics(limit: Int = 5) -> [String] {
        let topics = Array(Set(chatHistory.map { $0.topic }))
        return Array(topics.prefix(limit))
    }
    
    func getLastQuery(aboutTopic topic: String) -> HistoryEntry? {
        return chatHistory.last { $0.topic == topic }
    }
} 