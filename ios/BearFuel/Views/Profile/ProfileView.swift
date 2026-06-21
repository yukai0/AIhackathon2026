import SwiftUI

struct ProfileView: View {
    @ObservedObject private var store = ProfileStore.shared
    @State private var profile: UserProfile = ProfileStore.shared.profile
    @State private var customDislike = ""
    var onBodyStatsEntered: () -> Void = {}

    private let activityLevels = ["sedentary", "light", "moderate", "active", "very_active"]
    private let activityLabels = ["Sedentary", "Light", "Moderate", "Active", "Very Active"]
    private let goalTypes = ["cut", "maintain", "lean_gain", "recomp", "athletic_performance"]
    private let goalLabels = ["Cut", "Maintain", "Lean Gain", "Recomp", "Athletic Performance"]
    private let sexOptions = ["male", "female", "unspecified"]
    private let diningHalls: [(display: String, apiName: String)] = [
        ("Crossroads", "Crossroads"),
        ("Foothill", "Foothill"),
        ("Clark Kerr", "ClarkKerr"),
        ("Cafe 3", "Cafe3"),
    ]
    private let dietaryOptions = ["vegan", "vegetarian", "halal", "kosher"]
    private let allergenOptions = ["milk", "egg", "fish", "shellfish", "treenut", "wheat", "peanut", "soy", "sesame", "gluten", "pork"]
    private let dislikedFoodOptions = ["beef", "pork", "chicken", "eggs", "fish", "tofu", "beans", "rice", "pasta", "cheese", "yogurt", "cake", "dessert", "spicy"]

    var body: some View {
        NavigationStack {
            ZStack {
                CampusBackdrop(intensity: 0.75)
                ScrollView {
                    VStack(spacing: 16) {
                        profileHero
                        bodyStatsCard
                        goalsCard
                        computedTargetsCard
                        diningHallCard
                        preferencesCard
                        resourcesCard
                        disclaimerCard
                    }
                    .padding(16)
                    .padding(.bottom, 18)
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveAndRegenerate()
                    } label: {
                        Label("Save", systemImage: "checkmark.circle.fill")
                            .fontWeight(.semibold)
                    }
                }
            }
            .onAppear { profile = store.profile }
        }
    }

    private var profileHero: some View {
        let timeline = profile.goalTimelineWeeks ?? 12
        let goalWeight = profile.goalWeightKg ?? profile.weightKg
        return GradientCardView(gradient: BerkeleyTheme.heroGradient) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.berkeleyGold.opacity(0.18))
                    .frame(width: 170, height: 54)
                    .rotationEffect(.degrees(-18))
                    .offset(x: 96, y: -46)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.11))
                    .frame(width: 122, height: 44)
                    .rotationEffect(.degrees(20))
                    .offset(x: 104, y: 54)

                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Personal Fuel Profile")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white.opacity(0.85))
                            Text(label(for: profile.goalType, values: goalTypes, labels: goalLabels))
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundColor(.berkeleyGold)
                    }

                    HStack(spacing: 10) {
                        ProfileHeroMetric(icon: "scalemass.fill", value: oneDecimal(profile.weightKg), label: "kg now")
                        ProfileHeroMetric(icon: "target", value: oneDecimal(goalWeight), label: "kg goal")
                        ProfileHeroMetric(icon: "calendar", value: "\(timeline)", label: "weeks")
                    }
                }
                .padding(20)
            }
        }
        .cardEntrance(delay: 0.04)
    }

    private var bodyStatsCard: some View {
        BerkeleyCard(padding: 16) {
            VStack(alignment: .leading, spacing: 16) {
                BerkeleySectionHeader(title: "Body Stats", subtitle: "Used to estimate daily targets", icon: "figure.run")
                ProfileSliderRow(
                    title: "Height",
                    icon: "ruler.fill",
                    value: $profile.heightCm,
                    range: 140...220,
                    step: 1,
                    valueText: "\(Int(profile.heightCm)) cm",
                    color: .berkeleyBlue
                )
                ProfileSliderRow(
                    title: "Weight",
                    icon: "scalemass.fill",
                    value: $profile.weightKg,
                    range: 40...150,
                    step: 0.5,
                    valueText: "\(oneDecimal(profile.weightKg)) kg",
                    color: .campusMint
                )
                StepperRow(title: "Age", icon: "calendar", valueText: "\(profile.age)", color: .berkeleyGold) {
                    Stepper("", value: $profile.age, in: 13...100)
                        .labelsHidden()
                }
                ProfileOptionChips(
                    title: "Sex",
                    options: sexOptions,
                    selected: $profile.sex,
                    color: .berkeleyBlue,
                    label: { $0.capitalized }
                )
            }
        }
        .cardEntrance(delay: 0.08)
    }

    private var goalsCard: some View {
        BerkeleyCard(padding: 16) {
            VStack(alignment: .leading, spacing: 16) {
                BerkeleySectionHeader(title: "Activity & Goal", subtitle: goalPaceText, icon: "target")

                PickerRow(
                    title: "Activity",
                    icon: "bolt.fill",
                    color: .bayBlue,
                    value: label(for: profile.activityLevel, values: activityLevels, labels: activityLabels)
                ) {
                    Picker("Activity", selection: $profile.activityLevel) {
                        ForEach(Array(zip(activityLevels, activityLabels)), id: \.0) { value, label in
                            Text(label).tag(value)
                        }
                    }
                    .pickerStyle(.menu)
                }

                PickerRow(
                    title: "Goal",
                    icon: "flag.checkered",
                    color: .berkeleyGold,
                    value: label(for: profile.goalType, values: goalTypes, labels: goalLabels)
                ) {
                    Picker("Goal", selection: $profile.goalType) {
                        ForEach(Array(zip(goalTypes, goalLabels)), id: \.0) { value, label in
                            Text(label).tag(value)
                        }
                    }
                    .pickerStyle(.menu)
                }

                ProfileSliderRow(
                    title: "Goal Weight",
                    icon: "target",
                    value: Binding(
                        get: { profile.goalWeightKg ?? profile.weightKg },
                        set: { profile.goalWeightKg = $0 }
                    ),
                    range: 40...150,
                    step: 0.5,
                    valueText: "\(oneDecimal(profile.goalWeightKg ?? profile.weightKg)) kg",
                    color: .poppy
                )

                StepperRow(title: "Timeline", icon: "calendar.badge.clock", valueText: "\(profile.goalTimelineWeeks ?? 12) weeks", color: .campusMint) {
                    Stepper(
                        "",
                        value: Binding(
                            get: { profile.goalTimelineWeeks ?? 12 },
                            set: { profile.goalTimelineWeeks = $0 }
                        ),
                        in: 1...104
                    )
                    .labelsHidden()
                }

                StepperRow(title: "Meals per day", icon: "fork.knife", valueText: "\(profile.mealsPerDay)", color: .berkeleyBlue) {
                    Stepper("", value: $profile.mealsPerDay, in: 1...6)
                        .labelsHidden()
                }

                goalPaceBadge
            }
        }
        .cardEntrance(delay: 0.12)
    }

    private var computedTargetsCard: some View {
        let targets = computeTargets()
        return BerkeleyCard(padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                BerkeleySectionHeader(title: "Computed Targets", subtitle: "The generator fine-tunes these with your filters", icon: "chart.bar.xaxis")
                HStack(spacing: 10) {
                    MetricPill(icon: "flame.fill", title: "BMR", value: "\(Int(targets.0)) kcal", color: .orange)
                    MetricPill(icon: "bolt.fill", title: "TDEE", value: "\(Int(targets.1)) kcal", color: .berkeleyBlue)
                }
                SafetyContextCard(
                    icon: filterStatusIcon,
                    title: filterStatusTitle,
                    message: filterStatusMessage,
                    color: filterStatusColor
                )
            }
        }
        .cardEntrance(delay: 0.16)
    }

    private var diningHallCard: some View {
        BerkeleyCard(padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                BerkeleySectionHeader(title: "Dining Hall", subtitle: "Primary menu source", icon: "mappin.and.ellipse")
                FlowLayout(spacing: 8) {
                    ForEach(diningHalls, id: \.apiName) { hall in
                        SelectionChip(
                            title: hall.display,
                            icon: "mappin.circle.fill",
                            isSelected: (profile.preferredLocations.first ?? "Crossroads") == hall.apiName,
                            color: .bayBlue
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.84)) {
                                profile.preferredLocations = [hall.apiName]
                            }
                        }
                    }
                }
            }
        }
        .cardEntrance(delay: 0.20)
    }

    private var preferencesCard: some View {
        BerkeleyCard(padding: 16) {
            VStack(alignment: .leading, spacing: 18) {
                BerkeleySectionHeader(title: "Preferences & Exclusions", subtitle: "Tap chips individually", icon: "slider.horizontal.3")

                PreferenceGroup(title: "Dietary Preferences") {
                    FlowToggleSection(title: "Diet", options: dietaryOptions, selected: $profile.dietRestrictions)
                }

                PreferenceGroup(title: "Allergen Exclusions") {
                    FlowToggleSection(title: "Allergens", options: allergenOptions, selected: $profile.excludeAllergens)
                }

                PreferenceGroup(title: "Food Dislikes") {
                    FlowToggleSection(title: "Dislikes", options: dislikedFoodOptions, selected: $profile.dislikedFoods)
                    HStack(spacing: 8) {
                        TextField("Add food to avoid", text: $customDislike)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.systemBackground).opacity(0.80), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .onSubmit(addCustomDislike)
                        Button(action: addCustomDislike) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(customDislike.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .berkeleyBlue)
                        }
                        .disabled(customDislike.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .cardEntrance(delay: 0.24)
    }

    private var resourcesCard: some View {
        BerkeleyCard(padding: 16) {
            Link(destination: URL(string: "https://dining.berkeley.edu/dietitian/")!) {
                HStack(spacing: 12) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.poppy)
                        .frame(width: 42, height: 42)
                        .background(Color.poppy.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Berkeley Dietitian")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Official campus nutrition resource")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
            }
        }
        .cardEntrance(delay: 0.28)
    }

    private var disclaimerCard: some View {
        Text("Nutrition estimates only. Not medical advice. If you have health concerns, please consult a medical professional.")
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 10)
            .cardEntrance(delay: 0.32)
    }

    private var goalPaceText: String {
        let goalWeight = profile.goalWeightKg ?? profile.weightKg
        let weeks = Double(max(profile.goalTimelineWeeks ?? 12, 1))
        let weeklyChange = abs(goalWeight - profile.weightKg) / weeks
        if weeklyChange >= 1.0 { return "Aggressive pace" }
        if weeklyChange >= 0.5 { return "Challenging pace" }
        return "Sustainable pace"
    }

    private var goalPaceBadge: some View {
        let color: Color = goalPaceText == "Aggressive pace" ? .poppy : goalPaceText == "Challenging pace" ? .berkeleyGold : .campusMint
        return SafetyContextCard(
            icon: goalPaceText == "Sustainable pace" ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
            title: goalPaceText,
            message: goalPaceMessage,
            color: color
        )
    }

    private var goalPaceMessage: String {
        switch goalPaceText {
        case "Aggressive pace":
            return "This timeline may require targets that are hard to meet safely with dining hall options."
        case "Challenging pace":
            return "The generator will prioritize balanced meals and flag macro limits."
        default:
            return "This gives the meal planner more room to keep portions practical."
        }
    }

    private var filterStatusIcon: String {
        filterCount >= 9 ? "exclamationmark.triangle.fill" : "checkmark.seal.fill"
    }

    private var filterStatusTitle: String {
        filterCount >= 9 ? "Narrow filters" : "Filters balanced"
    }

    private var filterStatusMessage: String {
        if filterCount >= 9 {
            return "Many restrictions may leave too few foods for a complete plan."
        }
        return "Plans will avoid exclusions and warn when selected meals exceed daily limits."
    }

    private var filterStatusColor: Color {
        filterCount >= 9 ? .poppy : .campusMint
    }

    private var filterCount: Int {
        profile.dietRestrictions.count + profile.excludeAllergens.count + profile.dislikedFoods.count
    }

    private func saveAndRegenerate() {
        store.profile = profile
        PlanStore.shared.clear()
        NotificationCenter.default.post(name: .bearfuelRegeneratePlan, object: nil)
        onBodyStatsEntered()
    }

    private func addCustomDislike() {
        let cleaned = customDislike
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !cleaned.isEmpty else { return }
        if !profile.dislikedFoods.contains(cleaned) {
            profile.dislikedFoods.append(cleaned)
        }
        customDislike = ""
    }

    private func computeTargets() -> (Double, Double) {
        let bmr: Double
        switch profile.sex {
        case "male":
            bmr = 10 * profile.weightKg + 6.25 * profile.heightCm - 5 * Double(profile.age) + 5
        case "female":
            bmr = 10 * profile.weightKg + 6.25 * profile.heightCm - 5 * Double(profile.age) - 161
        default:
            bmr = 10 * profile.weightKg + 6.25 * profile.heightCm - 5 * Double(profile.age) - 78
        }
        let multipliers = ["sedentary": 1.2, "light": 1.375, "moderate": 1.55, "active": 1.725, "very_active": 1.9]
        let tdee = bmr * (multipliers[profile.activityLevel] ?? 1.55)
        return (bmr, tdee)
    }

    private func label(for value: String, values: [String], labels: [String]) -> String {
        guard let index = values.firstIndex(of: value), labels.indices.contains(index) else {
            return value.replacingOccurrences(of: "_", with: " ").capitalized
        }
        return labels[index]
    }

    private func oneDecimal(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }
}

private struct ProfileHeroMetric: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
            Text(value)
                .font(.headline.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption2.weight(.semibold))
                .opacity(0.82)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct ProfileSliderRow: View {
    let title: String
    let icon: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let valueText: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(color)
                    .frame(width: 30, height: 30)
                    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(valueText)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            Slider(value: $value, in: range, step: step)
                .tint(color)
        }
    }
}

private struct StepperRow<Control: View>: View {
    let title: String
    let icon: String
    let valueText: String
    let color: Color
    @ViewBuilder let control: () -> Control

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text(valueText)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.secondary)
                .monospacedDigit()
            control()
        }
    }
}

private struct PickerRow<Control: View>: View {
    let title: String
    let icon: String
    let color: Color
    let value: String
    @ViewBuilder let control: () -> Control

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            control()
                .labelsHidden()
        }
    }
}

private struct ProfileOptionChips: View {
    let title: String
    let options: [String]
    @Binding var selected: String
    let color: Color
    let label: (String) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            FlowLayout(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    SelectionChip(
                        title: label(option),
                        isSelected: selected == option,
                        color: color
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.84)) {
                            selected = option
                        }
                    }
                }
            }
        }
    }
}

private struct PreferenceGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.bold))
            content()
        }
    }
}

private struct SafetyContextCard: View {
    let icon: String
    let title: String
    let message: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(12)
        .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - FlowToggleSection

struct FlowToggleSection: View {
    let title: String
    let options: [String]
    @Binding var selected: [String]

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { option in
                SelectionChip(
                    title: label(for: option),
                    icon: icon(for: option),
                    isSelected: selected.contains(option),
                    color: color(for: option)
                ) {
                    toggle(option)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func toggle(_ option: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.84)) {
            if selected.contains(option) {
                selected.removeAll { $0 == option }
            } else {
                selected.append(option)
            }
        }
    }

    private func label(for option: String) -> String {
        switch option {
        case "treenut": return "Tree Nut"
        default: return option.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func icon(for option: String) -> String {
        switch option {
        case "vegan", "vegetarian", "beans", "tofu": return "leaf.fill"
        case "halal", "kosher": return "checkmark.seal.fill"
        case "milk", "cheese", "yogurt": return "cup.and.saucer.fill"
        case "egg", "eggs": return "oval.fill"
        case "fish", "shellfish": return "fish.fill"
        case "beef", "pork", "chicken": return "fork.knife"
        case "cake", "dessert": return "birthday.cake.fill"
        case "spicy": return "flame.fill"
        default: return "xmark.circle.fill"
        }
    }

    private func color(for option: String) -> Color {
        switch option {
        case "vegan", "vegetarian", "beans", "tofu": return .campusMint
        case "milk", "egg", "eggs", "fish", "shellfish", "treenut", "wheat", "peanut", "soy", "sesame", "gluten": return .poppy
        case "halal", "kosher": return .berkeleyBlue
        case "cake", "dessert", "spicy": return .berkeleyGold
        default: return .bayBlue
        }
    }
}
