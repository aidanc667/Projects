import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var inputText = ""
    @State private var isSpeaking = false
    @State private var showingPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            PersonalityPickerView(selected: $viewModel.selectedPersonality, setPersonality: viewModel.setPersonality)
            // Animated head view
            AnimatedHeadView(isSpeaking: $isSpeaking, personality: viewModel.selectedPersonality)
                .frame(width: 200, height: 200)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.white)
            // Add CASS title and subtitle
            VStack(spacing: 2) {
                Text("C.A.S.S")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                Text("Conversational AI with Swappable Selves")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 2)
            .padding(.bottom, 8)
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.messages) { message in
                            MessageView(message: message)
                                .transition(.move(edge: .bottom))
                                .id(message.id)
                        }
                    }
                }
                .animation(.easeInOut, value: viewModel.messages)
                .frame(maxWidth: .infinity)
                .padding()
                .onChange(of: viewModel.messages) { _, newValue in
                    if let last = newValue.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input area
            VStack(spacing: 20) {
                // Microphone button
                Button(action: {
                    if viewModel.microphonePermissionGranted {
                        viewModel.toggleRecording()
                    } else {
                        showingPermissionAlert = true
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(viewModel.isRecording ? Color.red : Color.orange)
                            .frame(width: 120, height: 120)
                            .shadow(radius: 3)
                        
                        Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 50))
                    }
                }
                
                // Text input field
                if !viewModel.isContinuousListening {
                    HStack {
                        TextField("Type a message...", text: $inputText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(viewModel.isProcessing)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.orange)
                                .font(.title)
                        }
                        .disabled(inputText.isEmpty || viewModel.isProcessing)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 20)
            .background(Color.white)
        }
        .onChange(of: viewModel.messages) { oldValue, newValue in
            if !newValue.isEmpty && newValue.count > oldValue.count {
                isSpeaking = true
            } else {
                isSpeaking = false
            }
        }
        .alert("Microphone Access", isPresented: $showingPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Allow") {
                viewModel.requestMicrophonePermission()
            }
        } message: {
            Text("CASS needs access to your microphone for voice conversations. Would you like to allow microphone access?")
        }
        .overlay(
            // Recording indicator
            Group {
                if viewModel.isContinuousListening {
                    VStack {
                        Text("Listening...")
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.8))
                            .cornerRadius(20)
                    }
                    .padding(.bottom, 100)
                    .animation(.easeInOut, value: viewModel.isContinuousListening)
                }
            }
            , alignment: .bottom
        )
        .onAppear { viewModel.startAudioSession() }
        .onDisappear { viewModel.stopAudioSession() }
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        Task {
            await viewModel.sendMessage(inputText)
            inputText = ""
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
            
            VStack(alignment: message.isUser ? .trailing : .leading) {
                Text(message.content)
                    .padding()
                    .background(message.isUser ? Color.orange : Color.gray.opacity(0.2))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(16)
            }
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

struct PersonalityPickerView: View {
    @Binding var selected: ChatViewModel.Personality
    var setPersonality: (ChatViewModel.Personality) -> Void
    var body: some View {
        HStack(spacing: 16) {
            ForEach(ChatViewModel.Personality.allCases) { personality in
                Button(action: {
                    setPersonality(personality)
                }) {
                    Text(personality.rawValue)
                        .fontWeight(selected == personality ? .bold : .regular)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(selected == personality ? Color.orange.opacity(0.2) : Color.clear)
                        .cornerRadius(10)
                        .foregroundColor(selected == personality ? .orange : .primary)
                }
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}

#Preview {
    ChatView()
} 