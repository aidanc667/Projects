import Foundation
import SwiftUI

@MainActor
public class ChatViewModel: ObservableObject {
    @Published public private(set) var messages: [ChatMessage] = []
    @Published public private(set) var isProcessing = false
    
    public init() {}
    
    public func sendMessage(_ content: String) {
        let userMessage = ChatMessage(content: content, isFromUser: true)
        messages.append(userMessage)
        
        // Simulate AI response
        Task {
            isProcessing = true
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            let response = ChatMessage(content: "I received: \(content)", isFromUser: false)
            messages.append(response)
            isProcessing = false
        }
    }
    
    public func clearChat() {
        messages.removeAll()
    }
}

 