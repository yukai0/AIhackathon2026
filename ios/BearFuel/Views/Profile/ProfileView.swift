import SwiftUI

struct ProfileView: View {
    @ObservedObject private var store = ProfileStore.shared
    @State private var profile: UserProfile = ProfileStore.shared.profile

    private let activityLevels = ["sedentary", "light", "moderate", "active", "very_active"]
    private let activityLabels = ["Sedentary", "Light", "Moderate", "Active", "Very Active"]
    private let goalTypes = ["cut", "maintain", "lean_gain", "recomp", "athletic_performance"]
    private let goalLabels = ["Cut", "Maintain", "Lean Gain", "Recomp", "Athletic Performance"]
    private let sexOptions = ["male", "female", "unspecified"]
    private let diningHalls = ["Crossroads", "Foothill", "Clark Kerr", "Unit 1", "Unit 2"]
    private let dietaryOptions = ["vegan", "vegetarian", "halal", "kosher"]
    private let allergenOptions = ["milk", "egg", "fish", "shellfish", "treenut", "wheat", "peanut", "soy", "sesame", "gluten", "pork"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Body Stats") {
                    LabeledContent("Height") {
                        HStack {
                            Slider(value: $profile.heightCm, in: 140...220, step: 1)
                            Text("\(Int(profile.heightCm)) cm")
                                .frame(width: 60, alignment: .trailing)
                                .monospacedDigit()
                        }
                    }
                    LabeledContent("Weight") {
                        HStack {
                            Slider(value: $profile.weightKg, in: 40...150, step: 0.5)
                            Text("\(profile.weightKg, specifier: "%.1f") kg")
                                .frame(width: 60, alignment: .trailing)
                                .monospacedDigit()
                        }
                    }
                    Stepper("Age: \(profile.age)", value: $profile.age, in: 13...100)
                    Picker("Sex", selection: $profile.sex) {
                        ForEach(sexOptions, id: \.self) { s in
                            Text(s.capitalized).tag(s)
                        }
                    }
                }

                Section("Activity & Goal") {
                    Picker("Activity Level", selection: $profile.activityLevel) {
                        ForEach(Array(zip(activityLevels, activityLabels)), id: \.0) { val, label in
                            Text(label).tag(val)
                        }
                    }
                    Picker("Goal", selection: $profile.goalType) {
                        ForEach(Array(zip(goalTypes, goalLabels)), id: \.0) { val, label in
                            Text(label).tag(val)
                        }
                    }
                    Stepper("Meals/day: \(profile.mealsPerDay)", value: $profile.mealsPerDay, in: 1...6)
                }

                Section("Computed Targets") {
                    let (bmr, tdee) = computeTargets()
                    HStack { Text("BMR"); Spacer(); Text("\(Int(bmr)) kcal").foregroundColor(.secondary) }
                    HStack { Text("TDEE"); Spacer(); Text("\(Int(tdee)) kcal").foregroundColor(.secondary) }
                    Text("These are estimates. Actual targets set by the plan generator.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Dining Halls") {
                    ForEach(diningHalls, id: \.self) { hall in
                        Toggle(hall, isOn: Binding(
                            get: { profile.preferredLocations.contains(hall) },
                            set: { on in
                                if on { profile.preferredLocations.append(hall) }
                                else { profile.preferredLocations.removeAll { $0 == hall } }
                            }
                        ))
                    }
                }

                Section("Dietary Preferences") {
                    FlowToggleSection(title: "Diet", options: dietaryOptions, selected: $profile.dietRestrictions)
                }

                Section("Allergen Exclusions") {
                    FlowToggleSection(title: "Allergens", options: allergenOptions, selected: $profile.excludeAllergens)
                }

                Section("Resources") {
                    Link("Meet the Berkeley Dietitian",
                         destination: URL(string: "https://dining.berkeley.edu/dietitian/")!)
                }

                Section {
                    Text("Nutrition estimates only. Not medical advice. If you have health concerns, please consult a medical professional.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        store.profile = profile
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear { profile = store.profile }
        }
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
}

// MARK: - FlowToggleSection

struct FlowToggleSection: View {
    let title: String
    let options: [String]
    @Binding var selected: [String]

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { option in
                let isSelected = selected.contains(option)
                Button(action: {
                    if isSelected { selected.removeAll { $0 == option } }
                    else { selected.append(option) }
                }) {
                    Text(option.capitalized)
                        .font(.caption)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isSelected ? Color.berkeleyBlue : Color.subtleBackground)
                        .foregroundColor(isSelected ? .white : .primary)
                        .cornerRadius(CornerRadius.chip)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
