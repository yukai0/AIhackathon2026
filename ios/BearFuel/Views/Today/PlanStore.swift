import Foundation
import Combine

final class PlanStore: ObservableObject {
    static let shared = PlanStore()

    @Published private(set) var todayPlan: MealPlan? = nil

    private let planKey = "bearfuel.mealplan.v1"
    private let dateKey = "bearfuel.mealplan.date.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        let today = isoToday()
        guard UserDefaults.standard.string(forKey: dateKey) == today,
              let data = UserDefaults.standard.data(forKey: planKey),
              let saved = try? decoder.decode(MealPlan.self, from: data) else { return }
        todayPlan = saved
    }

    func save(_ plan: MealPlan) {
        todayPlan = plan
        if let data = try? encoder.encode(plan) {
            UserDefaults.standard.set(data, forKey: planKey)
            UserDefaults.standard.set(isoToday(), forKey: dateKey)
        }
    }

    func clear() {
        todayPlan = nil
        UserDefaults.standard.removeObject(forKey: planKey)
        UserDefaults.standard.removeObject(forKey: dateKey)
    }

    private func isoToday() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }
}
