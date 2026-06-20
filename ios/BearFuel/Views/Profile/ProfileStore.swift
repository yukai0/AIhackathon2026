import Foundation
import Combine

final class ProfileStore: ObservableObject {
    static let shared = ProfileStore()

    @Published var profile: UserProfile {
        didSet { save() }
    }

    private let key = "bearfuel.userprofile.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? decoder.decode(UserProfile.self, from: data) {
            profile = saved
        } else {
            profile = UserProfile()
        }
    }

    var hasCompletedOnboarding: Bool {
        profile.heightCm > 0 && profile.weightKg > 0 && profile.age > 0
    }

    private func save() {
        if let data = try? encoder.encode(profile) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
