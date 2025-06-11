import Foundation

struct SearchResult: Identifiable, Codable {
    let title: String
    let url: String
    let content: String
    
    var id: String { url }
} 