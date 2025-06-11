import SwiftUI

struct ProfileSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ChatViewModel
    
    @State private var name = ""
    @State private var interests: [String] = []
    @State private var newInterest = ""
    @State private var goals: [String] = []
    @State private var newGoal = ""
    @State private var selectedTone: UserProfile.TonePreference = .friendly
    @State private var currentStep = 0
    
    private let tones: [UserProfile.TonePreference] = [.professional, .casual, .friendly, .direct]
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                TabView(selection: $currentStep) {
                    // Name Input
                    VStack(spacing: 20) {
                        Text("What's your name?")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        TextField("Enter your name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }
                    .tag(0)
                    
                    // Interests
                    VStack(spacing: 20) {
                        Text("What are your interests?")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack {
                            TextField("Add an interest", text: $newInterest)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button(action: addInterest) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.horizontal)
                        
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                                ForEach(interests, id: \.self) { interest in
                                    InterestChip(text: interest) {
                                        interests.removeAll { $0 == interest }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    .tag(1)
                    
                    // Goals
                    VStack(spacing: 20) {
                        Text("What are your goals?")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack {
                            TextField("Add a goal", text: $newGoal)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button(action: addGoal) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.horizontal)
                        
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                                ForEach(goals, id: \.self) { goal in
                                    InterestChip(text: goal) {
                                        goals.removeAll { $0 == goal }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    .tag(2)
                    
                    // Communication Style
                    VStack(spacing: 20) {
                        Text("Preferred communication style?")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ForEach(tones, id: \.self) { tone in
                            Button(action: { selectedTone = tone }) {
                                HStack {
                                    Text(tone.rawValue.capitalized)
                                        .foregroundColor(selectedTone == tone ? .white : .primary)
                                    Spacer()
                                    if selectedTone == tone {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .background(selectedTone == tone ? Color.orange : Color.gray.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                Spacer()
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if currentStep < 3 {
                        Button("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .disabled(currentStep == 0 && name.isEmpty)
                    } else {
                        Button("Start Chatting") {
                            saveProfile()
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitle("Profile Setup", displayMode: .inline)
        }
    }
    
    private func addInterest() {
        guard !newInterest.isEmpty else { return }
        interests.append(newInterest)
        newInterest = ""
    }
    
    private func addGoal() {
        guard !newGoal.isEmpty else { return }
        goals.append(newGoal)
        newGoal = ""
    }
    
    private func saveProfile() {
        viewModel.createProfile(name: name)
        viewModel.updateProfile(
            interests: interests,
            goals: goals,
            tone: selectedTone
        )
        dismiss()
    }
}

struct InterestChip: View {
    let text: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Text(text)
                .font(.subheadline)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

#Preview {
    ProfileSetupView(viewModel: ChatViewModel())
} 