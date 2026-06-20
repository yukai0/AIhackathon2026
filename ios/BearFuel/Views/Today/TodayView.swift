import SwiftUI

struct TodayView: View {
    @StateObject private var vm = TodayViewModel()
    @State private var showDisclaimer = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerCard
                    if let plan = vm.plan {
                        targetsCard(plan: plan)
                        if !vm.limitWarnings.isEmpty {
                            warningCard(warnings: vm.limitWarnings)
                        }
                        ForEach(plan.meals) { meal in
                            MealCard(
                                meal: meal,
                                itemMap: vm.menuItems,
                                isEaten: { vm.isEaten(itemID: $0, in: meal) },
                                onToggleEaten: { vm.toggleEaten(itemID: $0, in: meal) },
                                onDelete: { vm.deleteItem(itemID: $0, from: meal) },
                                alternatives: { vm.alternatives(for: $0, in: meal) },
                                onSubstitute: { itemID, replacement in
                                    vm.substitute(itemID: itemID, with: replacement, in: meal)
                                }
                            )
                        }
                        if !plan.disclaimer.isEmpty {
                            disclaimerBanner(text: plan.disclaimer)
                        }
                    } else if !vm.isLoading {
                        emptyState
                    }
                }
                .padding()
            }
            .background(Color.subtleBackground.ignoresSafeArea())
            .navigationTitle("BearFuel")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    generateButton
                }
            }
            .overlay {
                if vm.isLoading {
                    loadingOverlay
                }
            }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    // MARK: - Subviews

    private var headerCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(vm.displayDate)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.berkeleyGold)
                }
                if let plan = vm.plan {
                    let locs = Set(plan.meals.map { $0.location })
                    Text(locs.joined(separator: " · "))
                        .font(.subheadline)
                        .foregroundColor(.berkeleyBlue)
                }
            }
            .padding()
        }
    }

    private func targetsCard(plan: MealPlan) -> some View {
        let totals = vm.progressTotals
        return CardView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Daily Progress")
                    .font(.headline)
                HStack(spacing: 22) {
                    ringWithLabel(
                        current: totals.kcal,
                        target: plan.targets.kcal,
                        label: "kcal",
                        color: .orange
                    )
                    ringWithLabel(
                        current: totals.proteinG,
                        target: plan.targets.proteinG,
                        label: "protein",
                        color: .berkeleyBlue
                    )
                    ringWithLabel(
                        current: totals.carbG,
                        target: plan.targets.carbG,
                        label: "carbs",
                        color: .green
                    )
                    ringWithLabel(
                        current: totals.fatG,
                        target: plan.targets.fatG,
                        label: "fat",
                        color: .berkeleyGold
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }

    private func warningCard(warnings: [NutritionLimitWarning]) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Label("Target Warnings", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundColor(.orange)
                ForEach(warnings) { warning in
                    Text(warning.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding()
        }
    }

    private func ringWithLabel(current: Double, target: Double, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                ProgressRing(current: current, target: target, color: color)
                    .frame(width: 60, height: 60)
                VStack(spacing: 1) {
                    Text(Int(current).formatted(.number))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text("/ \(Int(target).formatted(.number))")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(width: 44)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run")
                .font(.system(size: 56))
                .foregroundColor(.berkeleyBlue.opacity(0.4))
            Text("Ready to fuel your day?")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Generate your personalized meal plan using today's real Berkeley dining menu.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(action: { Task { await vm.generatePlan() } }) {
                Label("Generate Today's Plan", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.berkeleyBlue)
                    .cornerRadius(CornerRadius.button)
            }
            .disabled(vm.isLoading)
            .padding(.horizontal)
        }
        .padding(.top, 40)
    }

    private var generateButton: some View {
        Button(action: { Task { await vm.generatePlan() } }) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .foregroundColor(.berkeleyBlue)
        }
        .disabled(vm.isLoading)
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.4)
                    .tint(.white)
                Text("Building your plan with real\nBerkeley dining data…")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func disclaimerBanner(text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.bottom, 8)
    }
}

// MARK: - MealCard

struct MealCard: View {
    let meal: MealSlot
    let itemMap: [String: MenuItem]
    let isEaten: (String) -> Bool
    let onToggleEaten: (String) -> Void
    let onDelete: (String) -> Void
    let alternatives: (String) -> [MenuItem]
    let onSubstitute: (String, MenuItem) -> Void

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(meal.label, systemImage: mealIcon(meal.label))
                        .font(.headline)
                        .foregroundColor(.berkeleyBlue)
                    Spacer()
                    Text(meal.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                MacroRow(totals: meal.totals, compact: true)
                Divider()
                ForEach(meal.items, id: \.self) { itemId in
                    if let item = itemMap[itemId] {
                        DishRow(
                            item: item,
                            isEaten: isEaten(itemId),
                            onToggleEaten: { onToggleEaten(itemId) },
                            onDelete: { onDelete(itemId) },
                            alternatives: alternatives(itemId),
                            onSubstitute: { replacement in onSubstitute(itemId, replacement) }
                        )
                    } else {
                        MissingDishRow()
                    }
                }
            }
            .padding()
        }
    }

    private func mealIcon(_ label: String) -> String {
        switch label.lowercased() {
        case "brunch", "breakfast": return "sunrise.fill"
        case "lunch": return "sun.max.fill"
        case "dinner": return "moon.stars.fill"
        default: return "fork.knife"
        }
    }
}

// MARK: - DishRow

struct DishRow: View {
    let item: MenuItem
    var isEaten: Bool? = nil
    var onToggleEaten: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var alternatives: [MenuItem] = []
    var onSubstitute: ((MenuItem) -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let onToggleEaten {
                Button(action: onToggleEaten) {
                    Image(systemName: isEaten == true ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isEaten == true ? .green : .secondary)
                        .frame(width: 28, height: 42)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isEaten == true ? "Mark uneaten" : "Mark eaten")
            }
            FoodAvatar(item: item)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if item.nutrition.estimated {
                        Text("est.")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.12))
                            .cornerRadius(4)
                    }
                }
                if !item.servingDesc.isEmpty {
                    Text(item.servingDesc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                FlowLayout(spacing: 4) {
                    ForEach(item.dietFlags, id: \.self) { flag in
                        DietBadge(flag: flag)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text("\(Int(item.nutrition.kcal)) kcal")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("\(Int(item.nutrition.proteinG))g P")
                    .font(.caption)
                    .foregroundColor(.berkeleyBlue)
                if onDelete != nil || onSubstitute != nil {
                    Menu {
                        if let onSubstitute {
                            if alternatives.isEmpty {
                                Text("No alternatives")
                            } else {
                                Section("Substitute") {
                                    ForEach(alternatives) { replacement in
                                        Button(replacement.name) {
                                            onSubstitute(replacement)
                                        }
                                    }
                                }
                            }
                        }
                        if let onDelete {
                            Button(role: .destructive, action: onDelete) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct MissingDishRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 42, height: 42)
                .background(Color.secondary.opacity(0.12))
                .clipShape(Circle())
            Text("Menu item unavailable")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
