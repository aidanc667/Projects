import SwiftUI
import AVFoundation
import Network
import Speech

@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isProcessing = false
    @Published private(set) var microphonePermissionGranted = false
    @Published private(set) var isRecording = false
    @Published private(set) var isContinuousListening = false
    @Published var showingProfileSetup = false
    @Published var isSpeaking = false
    
    private let synthesizer: AVSpeechSynthesizer
    private let profileManager: UserProfileManager
    private let monitor: NWPathMonitor
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine: AVAudioEngine
    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 1.5 // Seconds of silence before processing
    private var lastProcessedText = ""
    private var isConnected = false
    private var currentBuffer = ""
    private var lastSpeechTime = Date()
    private var synthesizerDelegate: SpeechSynthesizerDelegate?
    
    private var tavilyApiKey: String
    
    // Enhanced CASS personality prompt with personalization
    private let cassPrompt = """
    You are C.A.S.S. (Conversational AI for Strategy and Suggestions), a sharp and direct strategic advisor. Think of yourself as a no-nonsense friend who gets straight to the point.

    Key traits:
    - Give ONE clear, actionable piece of advice
    - Keep responses under 2 sentences
    - Be bold and decisive
    - Use casual, conversational tone
    - Add ONE focused follow-up question
    - Cut straight to the solution
    """
    
    init() {
        // Initialize all stored properties first
        self.synthesizer = AVSpeechSynthesizer()
        self.profileManager = UserProfileManager.shared
        self.monitor = NWPathMonitor()
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        self.audioEngine = AVAudioEngine()
        
        // Initialize API key
        do {
            self.tavilyApiKey = try KeychainManager.shared.getApiKey(forService: "tavily")
        } catch {
            self.tavilyApiKey = "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"
            // Save default key to keychain for future use
            try? KeychainManager.shared.saveApiKey(tavilyApiKey, forService: "tavily")
        }
        
        // After all properties are initialized, we can use self
        let delegate = SpeechSynthesizerDelegate(viewModel: self)
        self.synthesizerDelegate = delegate
        self.synthesizer.delegate = delegate
        
        // Setup network monitoring
        setupNetworkMonitoring()
        
        // Check for existing profile and add welcome message
        if profileManager.currentProfile == nil {
            showingProfileSetup = true
        } else {
            addWelcomeMessage()
        }
    }
    
    private func addWelcomeMessage() {
        if let profile = profileManager.currentProfile {
            let timeOfDay = Calendar.current.component(.hour, from: Date()).timeOfDayGreeting
            let welcomeMessage = "Hey \(profile.name)! \(timeOfDay). How can I help you today?"
            let message = ChatMessage(content: welcomeMessage, isUser: false)
            messages.append(message)
            speakResponse(welcomeMessage)
        } else {
            let message = ChatMessage(content: "Hey! I'm C.A.S.S. How can I help you?", isUser: false)
            messages.append(message)
            speakResponse(message.content)
        }
    }
    
    func createProfile(name: String) {
        profileManager.createProfile(name: name)
        showingProfileSetup = false
        addWelcomeMessage()
    }
    
    func updateProfile(interests: [String], goals: [String], tone: UserProfile.TonePreference) {
        guard var profile = profileManager.currentProfile else { return }
        profile.interests = interests
        profile.goals = goals
        profile.preferredTone = tone
        profileManager.updateProfile(profile)
    }
    
    private func analyzeMessageForContext(_ text: String) -> String {
        // Extract potential topic from the message
        let topic = text.extractMainTopic()
        
        // Check if we have any previous context about this topic
        if let lastQuery = profileManager.getLastQuery(aboutTopic: topic) {
            return """
            Previous context about '\(topic)':
            - Last discussed on: \(lastQuery.timestamp.formatted())
            - Previous query: \(lastQuery.query)
            - Your response: \(lastQuery.response)
            """
        }
        return ""
    }
    
    func sendMessage(_ text: String) async {
        isProcessing = true
        
        let userMessage = ChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        
        // Get context from previous conversations
        let context = analyzeMessageForContext(text)
    
        // Call Tavily API
        guard let url = URL(string: "https://api.tavily.com/search") else {
            let errorMessage = "Error: Invalid URL"
            let assistantMessage = ChatMessage(content: errorMessage, isUser: false)
            messages.append(assistantMessage)
            speakResponse(errorMessage)
            isProcessing = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(tavilyApiKey, forHTTPHeaderField: "api-key")
        
        let body: [String: Any] = [
            "query": text,
            "include_answer": true,
            "search_depth": "advanced",
            "max_results": 5
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let errorMessage = "Error: Invalid Tavily response"
                let assistantMessage = ChatMessage(content: errorMessage, isUser: false)
                messages.append(assistantMessage)
                speakResponse(errorMessage)
                isProcessing = false
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = "Error: Tavily returned status \(httpResponse.statusCode)"
                let assistantMessage = ChatMessage(content: errorMessage, isUser: false)
                messages.append(assistantMessage)
                speakResponse(errorMessage)
                isProcessing = false
                return
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let answer = json["answer"] as? String {
                let assistantMessage = ChatMessage(content: answer, isUser: false)
                messages.append(assistantMessage)
                
                // Store the interaction in profile history
                profileManager.addHistoryEntry(
                    query: text,
                    response: answer,
                    topic: text.extractMainTopic()
                )
                
                speakResponse(answer)
            } else {
                let errorMessage = "Sorry, I couldn't generate a response."
                let assistantMessage = ChatMessage(content: errorMessage, isUser: false)
                messages.append(assistantMessage)
                speakResponse(errorMessage)
            }
            
        } catch {
            print("Tavily API error: \(error)")
            let errorMessage = "Sorry, I encountered an error while processing your request."
            let assistantMessage = ChatMessage(content: errorMessage, isUser: false)
            messages.append(assistantMessage)
            speakResponse(errorMessage)
        }
        
        isProcessing = false
    }
    
    func requestMicrophonePermission() {
        #if os(iOS)
        // First request speech recognition authorization
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                switch status {
                case .authorized:
                    print("Speech recognition authorized")
                    // Then request microphone permission using new API
                    if #available(iOS 17.0, *) {
                        let granted = await AVAudioApplication.requestRecordPermission()
                        self?.microphonePermissionGranted = granted
                        if granted {
                            print("Microphone access granted")
                        } else {
                            print("Microphone access denied")
                        }
                    } else {
                        // Fallback for older iOS versions
                        AVAudioSession.sharedInstance().requestRecordPermission { granted in
                            Task { @MainActor in
                                self?.microphonePermissionGranted = granted
                                if granted {
                                    print("Microphone access granted")
                                } else {
                                    print("Microphone access denied")
                                }
                            }
                        }
                    }
                case .denied:
                    print("Speech recognition permission denied")
                    self?.microphonePermissionGranted = false
                case .restricted:
                    print("Speech recognition permission restricted")
                    self?.microphonePermissionGranted = false
                case .notDetermined:
                    print("Speech recognition permission not determined")
                    self?.microphonePermissionGranted = false
                @unknown default:
                    print("Speech recognition permission unknown")
                    self?.microphonePermissionGranted = false
                }
            }
        }
        #endif
    }
    
    func startContinuousListening() {
        guard !isContinuousListening else { return }
        isContinuousListening = true
        startRecording()
    }
    
    func stopContinuousListening() {
        isContinuousListening = false
        stopRecording()
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
            return
        }
        
        // Create and configure the speech recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        // Start audio engine and recognition
        let inputNode = audioEngine.inputNode
        
        // Use the native format from the input hardware
        let recordingFormat = inputNode.inputFormat(forBus: 0)
        print("Using audio format: \(recordingFormat.description)")
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.lastSpeechTime = Date() // Update last speech time when audio is detected
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecording = true
            
            // Start recognition task
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    let recognizedText = result.bestTranscription.formattedString
                    if recognizedText != currentBuffer {
                        currentBuffer = recognizedText
                        Task { @MainActor in
                            await self.checkForSpeechPause()
                        }
                    }
                }
                
                if error != nil || (result?.isFinal ?? false) {
                    self.stopRecording()
                    if self.isContinuousListening {
                        self.startRecording()
                    }
                }
            }
        } catch {
            print("Failed to start recording: \(error)")
            stopRecording()
        }
        
        // Start silence detection timer
        startSilenceDetectionTimer()
    }
    
    private func startSilenceDetectionTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkForSpeechPause()
            }
        }
    }
    
    private func checkForSpeechPause() async {
        guard isRecording,
              !currentBuffer.isEmpty,
              !isProcessing,
              !isSpeaking,
              Date().timeIntervalSince(lastSpeechTime) >= silenceThreshold else {
            return
        }
        
        let textToProcess = currentBuffer
        currentBuffer = ""
        
        await processRecognizedText(textToProcess)
    }
    
    private func processRecognizedText(_ text: String) async {
        guard text != lastProcessedText else { return }
        lastProcessedText = text
        
        isProcessing = true
        let userMessage = ChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        
        // Get context from previous conversations
        let context = analyzeMessageForContext(text)
        
        // Call Tavily API
        guard let url = URL(string: "https://api.tavily.com/search") else {
            let errorMessage = "Error: Invalid URL"
            let assistantMessage = ChatMessage(content: errorMessage, isUser: false)
            messages.append(assistantMessage)
            if !isRecording || isContinuousListening {
                speakResponse(errorMessage)
            }
            isProcessing = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(tavilyApiKey, forHTTPHeaderField: "api-key")
        
        let body: [String: Any] = [
            "query": text,
            "include_answer": true,
            "search_depth": "advanced",
            "max_results": 5
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let errorMessage = "Error: Invalid Tavily response"
                let assistantMessage = ChatMessage(content: errorMessage, isUser: false)
                messages.append(assistantMessage)
                if !isRecording || isContinuousListening {
                    speakResponse(errorMessage)
                }
                isProcessing = false
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = "Error: Tavily returned status \(httpResponse.statusCode)"
                let assistantMessage = ChatMessage(content: errorMessage, isUser: false)
                messages.append(assistantMessage)
                if !isRecording || isContinuousListening {
                    speakResponse(errorMessage)
                }
                isProcessing = false
                return
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let answer = json["answer"] as? String {
                let assistantMessage = ChatMessage(content: answer, isUser: false)
                messages.append(assistantMessage)
                
                // Store the interaction in profile history
                profileManager.addHistoryEntry(
                    query: text,
                    response: answer,
                    topic: text.extractMainTopic()
                )
                
                if !isRecording || isContinuousListening {
                    speakResponse(answer)
                }
            } else {
                let errorMessage = "Sorry, I couldn't generate a response."
                let assistantMessage = ChatMessage(content: errorMessage, isUser: false)
                messages.append(assistantMessage)
                if !isRecording || isContinuousListening {
                    speakResponse(errorMessage)
                }
            }
            
        } catch {
            print("Tavily API error: \(error)")
            let errorMessage = "Sorry, I encountered an error while processing your request."
            let assistantMessage = ChatMessage(content: errorMessage, isUser: false)
            messages.append(assistantMessage)
            if !isRecording || isContinuousListening {
                speakResponse(errorMessage)
            }
        }
        
        isProcessing = false
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        silenceTimer?.invalidate()
        silenceTimer = nil
        isRecording = false
        currentBuffer = ""
    }
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: DispatchQueue.global())
    }
    
    func speakResponse(_ text: String) {
        isSpeaking = true
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // Configure audio session for speech synthesis
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session for speech: \(error)")
        }
        
        synthesizer.speak(utterance)
    }
    
    func checkMicrophonePermission() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            Task { @MainActor [weak self] in
                switch authStatus {
                case .authorized:
                    // Request microphone permission using the new API
                    do {
                        try await AVAudioApplication.requestRecordPermission()
                        self?.microphonePermissionGranted = true
                    } catch {
                        self?.microphonePermissionGranted = false
                    }
                default:
                    self?.microphonePermissionGranted = false
                }
            }
        }
    }
}

// Helper Extensions
private extension String {
    func extractMainTopic() -> String {
        // Simple topic extraction - in real app, use NLP
        let words = self.lowercased().split(separator: " ")
        let stopWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "is", "are"])
        let mainWords = words.filter { !stopWords.contains(String($0)) }
        return String(mainWords.first ?? "general")
    }
}

private extension Int {
    var timeOfDayGreeting: String {
        switch self {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}

// Speech synthesizer delegate to handle speech status
private class SpeechSynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate {
    private weak var viewModel: ChatViewModel?
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            viewModel?.isSpeaking = false
            // If we're in continuous listening mode, make sure we're recording
            if viewModel?.isContinuousListening == true && viewModel?.isRecording == false {
                viewModel?.startRecording()
            }
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            viewModel?.isSpeaking = true
            // Stop recording while speaking to avoid picking up the AI's voice
            viewModel?.stopRecording()
        }
    }
} 