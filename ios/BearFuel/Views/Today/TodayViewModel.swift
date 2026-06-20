import Foundation
import SwiftUI

@MainActor
final class TodayViewModel: ObservableObject {
    @Published var plan: MealPlan? = nil
    @Published var menuItems: [String: MenuItem] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let api = APIClient.shared
    private let profileStore = ProfileStore.shared

    var todayString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    var displayDate: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .full
        fmt.timeStyle = .none
        return fmt.string(from: Date())
    }

    func generatePlan() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetchedPlan = try await api.generatePlan(
                profile: profileStore.profile,
                date: todayString
            )
            plan = fetchedPlan
            await loadMenuItems(for: fetchedPlan)
        } catch {
            errorMessage = error.localizedDescription
            loadFallbackPlan()
        }
        isLoading = false
    }

    private func loadMenuItems(for fetchedPlan: MealPlan) async {
        let allIds = Set(fetchedPlan.meals.flatMap { $0.items })
        do {
            let items = try await api.fetchMenu(date: todayString)
            let relevantItems = items.filter { allIds.contains($0.id) }
            menuItems = Dictionary(uniqueKeysWithValues: relevantItems.map { ($0.id, $0) })
        } catch {
            // Menu items are non-critical — plan still shows
        }
    }

    private func loadFallbackPlan() {
        guard let url = Bundle.main.url(forResource: "demo_plan", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let fallback = try? JSONDecoder().decode(MealPlan.self, from: data) else { return }
        plan = fallback
    }
}
