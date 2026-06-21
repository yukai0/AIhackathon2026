import Foundation
import SwiftUI

struct NutritionLimitWarning: Identifiable {
    let id: String
    let message: String
}

@MainActor
final class TodayViewModel: ObservableObject {
    @Published var plan: MealPlan? = nil
    @Published var menuItems: [String: MenuItem] = [:]
    @Published private var eatenItemKeys: Set<String> = []
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
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetchedPlan = try await api.generatePlan(
                profile: profileStore.profile,
                date: todayString
            )
            plan = fetchedPlan
            eatenItemKeys = []
            await loadMenuItems(for: fetchedPlan)
        } catch {
            if !loadFallbackPlan() {
                errorMessage = error.localizedDescription
            }
        }
    }

    var progressTotals: MacroTotals {
        guard let plan else { return .zero }
        var total = MacroTotals.zero
        for meal in plan.meals {
            for itemID in meal.items where isEaten(itemID: itemID, in: meal) {
                if let item = menuItems[itemID] {
                    total.add(item.nutrition)
                }
            }
        }
        return total
    }

    var plannedTotals: MacroTotals {
        guard let plan else { return .zero }
        return totals(for: plan.meals.flatMap { $0.items }, fallback: plan.dayTotals)
    }

    var limitWarnings: [NutritionLimitWarning] {
        guard let plan else { return [] }
        let planned = plannedTotals
        let eaten = progressTotals
        var warnings: [NutritionLimitWarning] = []

        warnings.append(contentsOf: warningsForTotals(
            planned,
            targets: plan.targets,
            prefix: "Planned"
        ))

        warnings.append(contentsOf: warningsForTotals(
            eaten,
            targets: plan.targets,
            prefix: "Eaten"
        ))

        return warnings
    }

    var allWarnings: [NutritionLimitWarning] {
        var warnings = plan?.warnings?.enumerated().map { index, message in
            NutritionLimitWarning(id: "plan-\(index)", message: message)
        } ?? []
        warnings.append(contentsOf: limitWarnings)
        return warnings
    }

    func isEaten(itemID: String, in meal: MealSlot) -> Bool {
        eatenItemKeys.contains(itemKey(itemID: itemID, meal: meal))
    }

    func toggleEaten(itemID: String, in meal: MealSlot) {
        let key = itemKey(itemID: itemID, meal: meal)
        if eatenItemKeys.contains(key) {
            eatenItemKeys.remove(key)
        } else {
            eatenItemKeys.insert(key)
        }
    }

    func deleteItem(itemID: String, from meal: MealSlot) {
        guard var currentPlan = plan,
              let mealIndex = currentPlan.meals.firstIndex(where: { $0.id == meal.id }),
              let itemIndex = currentPlan.meals[mealIndex].items.firstIndex(of: itemID) else { return }

        eatenItemKeys.remove(itemKey(itemID: itemID, meal: meal))
        currentPlan.meals[mealIndex].items.remove(at: itemIndex)
        refreshTotals(in: &currentPlan)
        plan = currentPlan
    }

    func substitute(itemID: String, with replacement: MenuItem, in meal: MealSlot) {
        guard var currentPlan = plan,
              let mealIndex = currentPlan.meals.firstIndex(where: { $0.id == meal.id }),
              let itemIndex = currentPlan.meals[mealIndex].items.firstIndex(of: itemID) else { return }

        eatenItemKeys.remove(itemKey(itemID: itemID, meal: meal))
        currentPlan.meals[mealIndex].items[itemIndex] = replacement.id
        refreshTotals(in: &currentPlan)
        plan = currentPlan
    }

    func alternatives(for itemID: String, in meal: MealSlot) -> [MenuItem] {
        let currentItem = menuItems[itemID]
        let usedIDs = Set(meal.items)
        let sameMealPeriod = menuItems.values.filter { candidate in
            candidate.id != itemID
            && !usedIDs.contains(candidate.id)
            && candidate.mealPeriod.localizedCaseInsensitiveCompare(currentItem?.mealPeriod ?? meal.label) == .orderedSame
        }

        let candidates = sameMealPeriod.isEmpty
            ? menuItems.values.filter { $0.id != itemID && !usedIDs.contains($0.id) }
            : sameMealPeriod

        return candidates.sorted { lhs, rhs in
            let lhsSameStation = lhs.station == currentItem?.station
            let rhsSameStation = rhs.station == currentItem?.station
            if lhsSameStation != rhsSameStation { return lhsSameStation }
            return lhs.nutrition.proteinG > rhs.nutrition.proteinG
        }
        .prefix(6)
        .map { $0 }
    }

    private func loadMenuItems(for fetchedPlan: MealPlan) async {
        let allIds = Set(fetchedPlan.meals.flatMap { $0.items })
        do {
            let items = try await api.fetchMenu(date: todayString)
            let relevantItems = items.filter { allIds.contains($0.id) }
            let allLiveItems = itemMap(from: items)
            let relevantMap = itemMap(from: relevantItems)
            menuItems = DemoData.menuItemsByID
                .merging(allLiveItems) { _, live in live }
                .merging(relevantMap) { _, live in live }
        } catch {
            menuItems = DemoData.menuItemsByID.filter { allIds.contains($0.key) }
        }
    }

    @discardableResult
    private func loadFallbackPlan() -> Bool {
        guard let url = Bundle.main.url(forResource: "demo_plan", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let fallback = try? JSONDecoder().decode(MealPlan.self, from: data) else { return false }
        plan = fallback
        menuItems = DemoData.menuItemsByID
        eatenItemKeys = []
        return true
    }

    private func itemMap(from items: [MenuItem]) -> [String: MenuItem] {
        Dictionary(items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private func itemKey(itemID: String, meal: MealSlot) -> String {
        "\(meal.id)::\(itemID)"
    }

    private func refreshTotals(in plan: inout MealPlan) {
        for index in plan.meals.indices {
            let mealTotals = totals(for: plan.meals[index].items, fallback: plan.meals[index].totals)
            plan.meals[index].totals = mealTotals
        }
        var dayTotals = MacroTotals.zero
        for meal in plan.meals {
            dayTotals.add(meal.totals)
        }
        plan.dayTotals = dayTotals
    }

    private func totals(for itemIDs: [String], fallback: MacroTotals) -> MacroTotals {
        var total = MacroTotals.zero
        var foundAnyItem = false
        for itemID in itemIDs {
            guard let item = menuItems[itemID] else { continue }
            total.add(item.nutrition)
            foundAnyItem = true
        }
        return foundAnyItem ? total : fallback
    }

    private func warningsForTotals(_ totals: MacroTotals, targets: MacroTotals, prefix: String) -> [NutritionLimitWarning] {
        [
            warningIfOver(id: "\(prefix)-kcal", label: "calories", amount: totals.kcal, target: targets.kcal, unit: "kcal", prefix: prefix),
            warningIfOver(id: "\(prefix)-protein", label: "protein", amount: totals.proteinG, target: targets.proteinG, unit: "g", prefix: prefix),
            warningIfOver(id: "\(prefix)-carbs", label: "carbs", amount: totals.carbG, target: targets.carbG, unit: "g", prefix: prefix),
            warningIfOver(id: "\(prefix)-fat", label: "fat", amount: totals.fatG, target: targets.fatG, unit: "g", prefix: prefix)
        ].compactMap { $0 }
    }

    private func warningIfOver(
        id: String,
        label: String,
        amount: Double,
        target: Double,
        unit: String,
        prefix: String
    ) -> NutritionLimitWarning? {
        guard amount > target else { return nil }
        let overBy = Int((amount - target).rounded())
        return NutritionLimitWarning(
            id: id,
            message: "\(prefix) \(label) is \(overBy) \(unit) over target."
        )
    }
}
