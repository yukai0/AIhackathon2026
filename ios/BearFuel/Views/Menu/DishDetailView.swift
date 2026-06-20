import SwiftUI

struct DishDetailView: View {
    let item: MenuItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                CardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        HStack {
                            Label(item.station, systemImage: "tray.full")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            if let carbon = item.carbon {
                                carbonBadge(carbon)
                            }
                        }
                        Text("\(item.location) · \(item.mealPeriod)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if !item.servingDesc.isEmpty {
                            Text("Serving: \(item.servingDesc)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        HStack(spacing: 6) {
                            ForEach(item.dietFlags, id: \.self) { flag in
                                DietBadge(flag: flag)
                            }
                        }
                    }
                    .padding()
                }

                // Nutrition facts
                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Nutrition Facts")
                                .font(.headline)
                            if item.nutrition.estimated {
                                Text("Estimated")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.orange.opacity(0.12))
                                    .cornerRadius(8)
                            }
                        }
                        MacroRow(totals: MacroTotals(
                            kcal: item.nutrition.kcal,
                            proteinG: item.nutrition.proteinG,
                            carbG: item.nutrition.carbG,
                            fatG: item.nutrition.fatG
                        ))
                        Divider()
                        nutrientRow("Calories", value: "\(Int(item.nutrition.kcal)) kcal", bold: true)
                        nutrientRow("Protein", value: "\(item.nutrition.proteinG.formatted(.number.precision(.fractionLength(1))))g")
                        nutrientRow("Carbohydrates", value: "\(item.nutrition.carbG.formatted(.number.precision(.fractionLength(1))))g")
                        nutrientRow("  Dietary Fiber", value: "\(item.nutrition.fiberG.formatted(.number.precision(.fractionLength(1))))g", indent: true)
                        nutrientRow("  Sugars", value: "\(item.nutrition.sugarG.formatted(.number.precision(.fractionLength(1))))g", indent: true)
                        nutrientRow("Total Fat", value: "\(item.nutrition.fatG.formatted(.number.precision(.fractionLength(1))))g")
                        nutrientRow("  Saturated Fat", value: "\(item.nutrition.satFatG.formatted(.number.precision(.fractionLength(1))))g", indent: true)
                        nutrientRow("Sodium", value: "\(Int(item.nutrition.sodiumMg)) mg")
                        nutrientRow("Cholesterol", value: "\(Int(item.nutrition.cholesterolMg)) mg")
                        if let co2 = item.carbonKgCo2 {
                            Divider()
                            nutrientRow("Carbon Footprint", value: "\(co2.formatted(.number.precision(.fractionLength(2)))) kg CO₂")
                        }
                    }
                    .padding()
                }

                // Allergens
                if !item.allergens.isEmpty {
                    CardView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Contains")
                                .font(.headline)
                            FlowLayout(spacing: 8) {
                                ForEach(item.allergens, id: \.self) { allergen in
                                    Text(allergen.capitalized)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .cornerRadius(CornerRadius.chip)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .padding()
        }
        .background(Color.subtleBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private func nutrientRow(_ label: String, value: String, bold: Bool = false, indent: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(bold ? .subheadline.weight(.semibold) : .subheadline)
                .foregroundColor(indent ? .secondary : .primary)
                .padding(.leading, indent ? 12 : 0)
            Spacer()
            Text(value)
                .font(bold ? .subheadline.weight(.semibold) : .subheadline)
                .foregroundColor(.primary)
        }
    }

    private func carbonBadge(_ tier: String) -> some View {
        let color: Color = tier == "low" ? .green : tier == "medium" ? .yellow : .red
        return HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(tier.capitalized + " CO₂")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
