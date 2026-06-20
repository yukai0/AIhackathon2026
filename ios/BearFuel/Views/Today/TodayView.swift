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
                        ForEach(plan.meals) { meal in
                            MealCard(meal: meal, itemMap: vm.menuItems)
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
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Daily Progress")
                    .font(.headline)
                HStack(spacing: 20) {
                    ringWithLabel(
                        current: plan.dayTotals.kcal,
                        target: plan.targets.kcal,
                        label: "kcal",
                        color: .orange
                    )
                    ringWithLabel(
                        current: plan.dayTotals.proteinG,
                        target: plan.targets.proteinG,
                        label: "protein",
                        color: .berkeleyBlue
                    )
                    ringWithLabel(
                        current: plan.dayTotals.carbG,
                        target: plan.targets.carbG,
                        label: "carbs",
                        color: .green
                    )
                    ringWithLabel(
                        current: plan.dayTotals.fatG,
                        target: plan.targets.fatG,
                        label: "fat",
                        color: .berkeleyGold
                    )
                }
                if !plan.notes.isEmpty {
                    Text(plan.notes)
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
                    Text("\(Int(current))")
                        .font(.system(size: 13, weight: .bold))
                    Text("/ \(Int(target))")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            Text(label)
                .font(.caption2)
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
            .padding(.horizontal)
        }
        .padding(.top, 40)
    }

    private var generateButton: some View {
        Button(action: { Task { await vm.generatePlan() } }) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .foregroundColor(.berkeleyBlue)
        }
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
                        DishRow(item: item)
                    } else {
                        Text(itemId)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                if !meal.rationale.isEmpty {
                    Text(meal.rationale)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .fixedSize(horizontal: false, vertical: true)
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

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
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
                HStack(spacing: 4) {
                    ForEach(item.dietFlags, id: \.self) { flag in
                        DietBadge(flag: flag)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(item.nutrition.kcal)) kcal")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("\(Int(item.nutrition.proteinG))g P")
                    .font(.caption)
                    .foregroundColor(.berkeleyBlue)
            }
        }
    }
}
