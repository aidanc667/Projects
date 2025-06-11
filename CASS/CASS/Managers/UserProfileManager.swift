import Foundation

@MainActor
class UserProfileManager: ObservableObject {
    @Published private(set) var currentProfile: UserProfile?
    private let userDefaults = UserDefaults.standard
    private let profileKey = "userProfile"
    
    static let shared = UserProfileManager()
    
    private init() {
        loadProfile()
    }
    
    private func loadProfile() {
        if let data = userDefaults.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.currentProfile = profile
        }
    }
    
    private func saveProfile() {
        guard let profile = currentProfile,
              let data = try? JSONEncoder().encode(profile) else {
            return
        }
        userDefaults.set(data, forKey: profileKey)
    }
    
    func createProfile(name: String) {
        currentProfile = UserProfile(name: name)
        saveProfile()
    }
    
    func updateProfile(_ profile: UserProfile) {
        currentProfile = profile
        saveProfile()
    }
    
    func addInterest(_ interest: String) {
        guard var profile = currentProfile else { return }
        if !profile.interests.contains(interest) {
            profile.interests.append(interest)
            updateProfile(profile)
        }
    }
    
    func addGoal(_ goal: String) {
        guard var profile = currentProfile else { return }
        if !profile.goals.contains(goal) {
            profile.goals.append(goal)
            updateProfile(profile)
        }
    }
    
    func setTonePreference(_ tone: UserProfile.TonePreference) {
        guard var profile = currentProfile else { return }
        profile.preferredTone = tone
        updateProfile(profile)
    }
    
    func addHistoryEntry(query: String, response: String, topic: String) {
        guard var profile = currentProfile else { return }
        profile.addHistoryEntry(query: query, response: response, topic: topic)
        updateProfile(profile)
    }
    
    func getRecentTopics() -> [String] {
        return currentProfile?.getRecentTopics() ?? []
    }
    
    func getLastQuery(aboutTopic topic: String) -> UserProfile.HistoryEntry? {
        return currentProfile?.getLastQuery(aboutTopic: topic)
    }
    
    func clearProfile() {
        currentProfile = nil
        userDefaults.removeObject(forKey: profileKey)
    }
} 