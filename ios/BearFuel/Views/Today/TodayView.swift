import SwiftUI

struct TodayView: View {
    @StateObject private var vm = TodayViewModel()

    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        heroCard
                        if let plan = vm.plan {
                            targetsCard(plan: plan)
                            if !vm.allWarnings.isEmpty {
                                planWarningsCard(warnings: vm.allWarnings)
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
                                    .padding(.top, 8)
                            }
                        } else if !vm.isLoading {
                            emptyState
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
                .navigationTitle("BearFuel")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        generateButton
                    }
                }
                .onAppear { Task { await vm.restoreMenuItemsIfNeeded() } }
                .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                    Button("OK") { vm.errorMessage = nil }
                } message: {
                    Text(vm.errorMessage ?? "")
                }
            }
            if vm.isLoading {
                loadingOverlay
            }
        }
    }

    // MARK: - Hero card

    private var heroCard: some View {
        GradientCardView(gradient: .berkeleyVibrant) {
            ZStack {
                // Decorative circles for depth (subtle)
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 120, height: 120)
                    .offset(x: 90, y: -30)
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 80, height: 80)
                    .offset(x: 110, y: 30)

                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(timeOfDayGreeting)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white.opacity(0.85))
                        Text(vm.displayDate)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        if let plan = vm.plan {
                            let locs = Set(plan.meals.map { $0.location }).sorted()
                            HStack(spacing: 6) {
                                ForEach(locs, id: \.self) { loc in
                                    Label(loc, systemImage: "mappin.circle.fill")
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                        .background(Color.white.opacity(0.20))
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color.berkeleyGold)
                        .shadow(color: Color.berkeleyGold.opacity(0.6), radius: 10)
                }
                .padding(20)
            }
        }
        .cardEntrance(delay: 0.05)
    }

    private var timeOfDayGreeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning ☀️" }
        if h < 17 { return "Good afternoon 🌤️" }
        return "Good evening 🌙"
    }

    // MARK: - Targets card

    private func targetsCard(plan: MealPlan) -> some View {
        let eaten = vm.progressTotals
        let pct = Int(min(eaten.kcal / max(plan.targets.kcal, 1), 1.0) * 100)
        return CardView {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Progress")
                            .font(.title3.bold())
                        Text("Tap items to mark as eaten")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(pct)%")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(LinearGradient.berkeleyVibrant)
                        .clipShape(Capsule())
                }

                HStack(spacing: 20) {
                    // Large calorie ring
                    ZStack {
                        GradientProgressRing(
                            current: eaten.kcal,
                            target: plan.targets.kcal,
                            colors: [Color(red:0.10,green:0.48,blue:0.92),
                                     Color(red:0.02,green:0.65,blue:0.80)],
                            lineWidth: 16
                        )
                        .frame(width: 116, height: 116)
                        VStack(spacing: 1) {
                            AnimatedCounter(value: eaten.kcal, format: "%.0f", color: .primary)
                                .font(.system(size: 24, weight: .bold))
                            Text("/ \(Int(plan.targets.kcal))")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text("kcal")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }

                    // Three smaller rings stacked
                    VStack(spacing: 12) {
                        miniRing(current: eaten.proteinG, target: plan.targets.proteinG, label: "protein",
                                 colors: [Color(red:0.10,green:0.75,blue:0.45), Color(red:0.04,green:0.88,blue:0.55)])
                        miniRing(current: eaten.carbG, target: plan.targets.carbG, label: "carbs",
                                 colors: [Color(red:1.00,green:0.70,blue:0.00), Color(red:1.00,green:0.85,blue:0.15)])
                        miniRing(current: eaten.fatG, target: plan.targets.fatG, label: "fat",
                                 colors: [Color(red:1.00,green:0.38,blue:0.25), Color(red:1.00,green:0.55,blue:0.35)])
                    }
                }
            }
            .padding(20)
        }
        .cardEntrance(delay: 0.12)
    }

    private func miniRing(current: Double, target: Double, label: String, colors: [Color]) -> some View {
        HStack(spacing: 10) {
            ZStack {
                GradientProgressRing(current: current, target: target, colors: colors, lineWidth: 7)
                    .frame(width: 42, height: 42)
                Text("\(Int(min(current / max(target, 1), 1.0) * 100))%")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.primary)
            }
            VStack(alignment: .leading, spacing: 1) {
                AnimatedCounter(value: current, format: "%.0f", color: .primary)
                    .font(.system(size: 14, weight: .bold))
                Text("/ \(Int(target))g \(label)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Plan warnings card

    private func planWarningsCard(warnings: [NutritionLimitWarning]) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Label("Plan Warnings", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundColor(Color(red:1.0,green:0.58,blue:0.0))
                ForEach(warnings) { w in
                    Text("• \(w.message)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
        }
        .cardEntrance(delay: 0.08)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(LinearGradient.berkeleyVibrant.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: "sparkles")
                    .font(.system(size: 46, weight: .light))
                    .foregroundColor(Color(red:0.10,green:0.48,blue:0.92))
            }
            VStack(spacing: 8) {
                Text("Ready to fuel your day?")
                    .font(.title3.bold())
                Text("Generate your personalized meal plan\nusing today's real Berkeley dining menu.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            Button(action: { Task { await vm.generatePlan() } }) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles").font(.system(size: 16, weight: .semibold))
                    Text("Generate Today's Plan").font(.headline.weight(.semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient.berkeleyVibrant)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color(red:0.10,green:0.48,blue:0.92).opacity(0.40), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 8)
        .padding(.top, 32)
    }

    // MARK: - Generate button

    private var generateButton: some View {
        Button(action: { Task { await vm.generatePlan() } }) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(LinearGradient.berkeleyVibrant)
        }
    }

    // MARK: - Loading overlay

    private var loadingOverlay: some View {
        AnalyzingLoadingOverlay()
    }

    // MARK: - Disclaimer banner

    private func disclaimerBanner(text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.bottom, 8)
    }
}

// MARK: - AnalyzingLoadingOverlay

struct AnalyzingLoadingOverlay: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.berkeleyBlue,
                    Color(red: 0.04, green: 0.45, blue: 0.55),
                    Color(red: 0.96, green: 0.42, blue: 0.17)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { proxy in
                ZStack {
                    FloatingShape(
                        color: .berkeleyGold,
                        size: CGSize(width: 150, height: 52),
                        cornerRadius: 24,
                        rotation: -18,
                        position: CGPoint(x: proxy.size.width * 0.18, y: proxy.size.height * 0.18),
                        animate: animate
                    )
                    FloatingShape(
                        color: .green,
                        size: CGSize(width: 118, height: 118),
                        cornerRadius: 18,
                        rotation: 16,
                        position: CGPoint(x: proxy.size.width * 0.86, y: proxy.size.height * 0.25),
                        animate: animate,
                        delay: 0.2
                    )
                    FloatingShape(
                        color: .white,
                        size: CGSize(width: 86, height: 42),
                        cornerRadius: 12,
                        rotation: 34,
                        position: CGPoint(x: proxy.size.width * 0.16, y: proxy.size.height * 0.72),
                        animate: animate,
                        delay: 0.1
                    )
                    FloatingShape(
                        color: .berkeleyGold,
                        size: CGSize(width: 98, height: 98),
                        cornerRadius: 16,
                        rotation: -28,
                        position: CGPoint(x: proxy.size.width * 0.78, y: proxy.size.height * 0.78),
                        animate: animate,
                        delay: 0.35
                    )

                    FloatingSymbol(
                        symbol: "fork.knife",
                        color: .white,
                        position: CGPoint(x: proxy.size.width * 0.27, y: proxy.size.height * 0.31),
                        animate: animate
                    )
                    FloatingSymbol(
                        symbol: "leaf.fill",
                        color: .green,
                        position: CGPoint(x: proxy.size.width * 0.72, y: proxy.size.height * 0.34),
                        animate: animate,
                        delay: 0.2
                    )
                    FloatingSymbol(
                        symbol: "flame.fill",
                        color: .orange,
                        position: CGPoint(x: proxy.size.width * 0.25, y: proxy.size.height * 0.62),
                        animate: animate,
                        delay: 0.35
                    )
                    FloatingSymbol(
                        symbol: "takeoutbag.and.cup.and.straw.fill",
                        color: .berkeleyGold,
                        position: CGPoint(x: proxy.size.width * 0.76, y: proxy.size.height * 0.61),
                        animate: animate,
                        delay: 0.1
                    )
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.white.opacity(0.16))
                        .frame(width: 128, height: 128)
                        .rotationEffect(.degrees(animate ? 10 : -10))
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.45), lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(animate ? -16 : 16))
                    Image(systemName: "sparkles")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(animate ? 1.08 : 0.94)
                }
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: animate)

                VStack(spacing: 8) {
                    Text("AI is analyzing")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Matching your stats with today's dining hall menu.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.86))
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 10) {
                    LoadingBadge(symbol: "person.fill", text: "profile")
                    LoadingBadge(symbol: "fork.knife", text: "menu")
                    LoadingBadge(symbol: "chart.bar.fill", text: "macros")
                }

                IndeterminateProgressBar()
                    .padding(.top, 4)
            }
            .padding(28)
            .frame(maxWidth: 330)
            .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .padding(.horizontal, 28)
        }
        .onAppear {
            animate = true
        }
    }
}

private struct FloatingShape: View {
    let color: Color
    let size: CGSize
    let cornerRadius: CGFloat
    let rotation: Double
    let position: CGPoint
    let animate: Bool
    var delay: Double = 0

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(color.opacity(0.22))
            .frame(width: size.width, height: size.height)
            .rotationEffect(.degrees(animate ? rotation : -rotation))
            .position(position)
            .offset(y: animate ? -12 : 12)
            .animation(.easeInOut(duration: 1.8).delay(delay).repeatForever(autoreverses: true), value: animate)
    }
}

private struct FloatingSymbol: View {
    let symbol: String
    let color: Color
    let position: CGPoint
    let animate: Bool
    var delay: Double = 0

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 26, weight: .bold))
            .foregroundColor(color.opacity(0.88))
            .padding(14)
            .background(Color.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 16))
            .position(position)
            .offset(y: animate ? 10 : -10)
            .animation(.easeInOut(duration: 1.6).delay(delay).repeatForever(autoreverses: true), value: animate)
    }
}

private struct LoadingBadge: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.16), in: Capsule())
    }
}

private struct IndeterminateProgressBar: View {
    @State private var offset: CGFloat = -0.38

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.25))
                Capsule()
                    .fill(Color.white)
                    .frame(width: geo.size.width * 0.38)
                    .offset(x: offset * geo.size.width)
            }
            .clipped()
        }
        .frame(height: 6)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                offset = 1.0
            }
        }
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
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            // Header strip — vibrant gradient, ~68pt tall
            ZStack(alignment: .bottomLeading) {
                mealGradient(for: meal.label)
                    .frame(height: 68)
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(meal.label)
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        Text(meal.location)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.85))
                    }
                    Spacer()
                    Image(systemName: mealIcon(for: meal.label))
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white.opacity(0.90))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            // Macro summary row
            MacroRow(totals: meal.totals, compact: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))

            Divider()

            // Dish rows
            VStack(spacing: 0) {
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
                        .padding(.horizontal, 16)
                        if itemId != meal.items.last {
                            Divider().padding(.leading, 70)
                        }
                    } else {
                        MissingDishRow()
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.09), radius: 12, x: 0, y: 5)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 22)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                appeared = true
            }
        }
    }

    private func mealIcon(for label: String) -> String {
        switch label.lowercased() {
        case "breakfast": return "sunrise.fill"
        case "brunch": return "sun.haze.fill"
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
                Text(item.diningHallPortionText)
                    .font(.caption)
                    .foregroundColor(.secondary)
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
