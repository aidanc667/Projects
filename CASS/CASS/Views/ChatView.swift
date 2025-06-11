import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageView(message: message)
                            .transition(.move(edge: .bottom))
                    }
                }
                .padding()
            }
            
            // Input area
            VStack(spacing: 8) {
                // Microphone button
                Button(action: {
                    if viewModel.isContinuousListening {
                        viewModel.stopContinuousListening()
                    } else {
                        viewModel.startContinuousListening()
                    }
                }) {
                    VStack {
                        Image(systemName: viewModel.isContinuousListening ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(viewModel.isContinuousListening ? .red : .orange)
                        
                        Text(viewModel.isContinuousListening ? "Stop Listening" : "Start Conversation")
                            .font(.caption)
                            .foregroundColor(viewModel.isContinuousListening ? .red : .orange)
                    }
                }
                .disabled(!viewModel.microphonePermissionGranted)
                .padding(.vertical, 8)
                
                // Status indicator
                if viewModel.isContinuousListening {
                    HStack {
                        Circle()
                            .fill(viewModel.isRecording ? .green : .orange)
                            .frame(width: 8, height: 8)
                        
                        Text(statusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 4)
                }
                
                // Text input
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $inputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isInputFocused)
                        .disabled(viewModel.isRecording)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                    }
                    .disabled(inputText.isEmpty || viewModel.isRecording)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(Color(.systemBackground))
            .shadow(radius: 2)
        }
        .onAppear {
            viewModel.checkMicrophonePermission()
        }
    }
    
    private var statusText: String {
        if viewModel.isSpeaking {
            return "CASS is speaking..."
        } else if viewModel.isProcessing {
            return "Processing..."
        } else if viewModel.isRecording {
            return "Listening..."
        } else {
            return "Ready..."
        }
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let text = inputText
        inputText = ""
        
        Task {
            await viewModel.sendMessage(text)
        }
    }
}

struct MessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            Text(message.content)
                .padding()
                .background(message.isUser ? Color.orange : Color(.systemGray6))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(16)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

#Preview {
    let viewModel = ChatViewModel()
    return ChatView(viewModel: viewModel)
} 