import SwiftUI

struct DishDetailView: View {
    let item: MenuItem

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ZStack {
            CampusBackdrop(intensity: 0.75)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    heroCard
                    nutritionOverview
                    nutritionFacts
                    if !item.allergens.isEmpty {
                        allergenCard
                    }
                    carbonCard
                }
                .padding(16)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Dish")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heroCard: some View {
        GradientCardView(gradient: mealGradient(for: item.mealPeriod)) {
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.white.opacity(0.16))
                    .frame(width: 170, height: 56)
                    .rotationEffect(.degrees(-18))
                    .offset(x: 92, y: -46)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 112, height: 46)
                    .rotationEffect(.degrees(22))
                    .offset(x: 108, y: 56)

                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 14) {
                        FoodAvatar(item: item)
                            .frame(width: 62, height: 62)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.name)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("\(displayLocation(item.location)) - \(item.mealPeriod)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white.opacity(0.84))
                        }
                    }

                    FlowLayout(spacing: 8) {
                        HeroBadge(icon: "tray.full.fill", text: item.station)
                        HeroBadge(icon: "fork.knife", text: item.diningHallPortionText)
                        if let carbon = item.carbon {
                            HeroBadge(icon: "leaf.fill", text: "\(carbon.capitalized) CO2")
                        }
                    }

                    if !item.dietFlags.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(item.dietFlags, id: \.self) { flag in
                                DietBadge(flag: flag)
                                    .background(Color.white.opacity(0.08), in: Capsule())
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .cardEntrance(delay: 0.04)
    }

    private var nutritionOverview: some View {
        BerkeleyCard(padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                BerkeleySectionHeader(title: "Nutrition Snapshot", subtitle: item.nutrition.estimated ? "Estimated values" : "Dining hall values", icon: "chart.pie.fill")
                LazyVGrid(columns: columns, spacing: 10) {
                    MetricPill(icon: "flame.fill", title: "Calories", value: "\(Int(item.nutrition.kcal)) kcal", color: .orange)
                    MetricPill(icon: "bolt.fill", title: "Protein", value: "\(oneDecimal(item.nutrition.proteinG))g", color: .berkeleyBlue)
                    MetricPill(icon: "leaf.fill", title: "Carbs", value: "\(oneDecimal(item.nutrition.carbG))g", color: .campusMint)
                    MetricPill(icon: "drop.fill", title: "Fat", value: "\(oneDecimal(item.nutrition.fatG))g", color: .berkeleyGold)
                }
            }
        }
        .cardEntrance(delay: 0.08)
    }

    private var nutritionFacts: some View {
        BerkeleyCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    BerkeleySectionHeader(title: "Nutrition Facts", icon: "list.bullet.rectangle.fill")
                    if item.nutrition.estimated {
                        Text("Estimated")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.12), in: Capsule())
                    }
                }

                Divider()
                nutrientRow("Calories", value: "\(Int(item.nutrition.kcal)) kcal", bold: true)
                nutrientRow("Protein", value: "\(oneDecimal(item.nutrition.proteinG))g")
                nutrientRow("Carbohydrates", value: "\(oneDecimal(item.nutrition.carbG))g")
                nutrientRow("Dietary Fiber", value: "\(oneDecimal(item.nutrition.fiberG))g", indent: true)
                nutrientRow("Sugars", value: "\(oneDecimal(item.nutrition.sugarG))g", indent: true)
                nutrientRow("Total Fat", value: "\(oneDecimal(item.nutrition.fatG))g")
                nutrientRow("Saturated Fat", value: "\(oneDecimal(item.nutrition.satFatG))g", indent: true)
                nutrientRow("Sodium", value: "\(Int(item.nutrition.sodiumMg)) mg")
                nutrientRow("Cholesterol", value: "\(Int(item.nutrition.cholesterolMg)) mg")
            }
        }
        .cardEntrance(delay: 0.12)
    }

    private var allergenCard: some View {
        BerkeleyCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                BerkeleySectionHeader(title: "Contains", subtitle: "Check dining hall labels before eating", icon: "exclamationmark.triangle.fill")
                FlowLayout(spacing: 8) {
                    ForEach(item.allergens, id: \.self) { allergen in
                        Text(allergen.capitalized)
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.poppy.opacity(0.12), in: Capsule())
                            .foregroundColor(.poppy)
                    }
                }
            }
        }
        .cardEntrance(delay: 0.16)
    }

    private var carbonCard: some View {
        BerkeleyCard(padding: 16) {
            HStack(spacing: 12) {
                Image(systemName: carbonIcon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(carbonColor)
                    .frame(width: 42, height: 42)
                    .background(carbonColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Carbon Impact")
                        .font(.headline)
                    Text(carbonText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .cardEntrance(delay: 0.20)
    }

    private var carbonIcon: String {
        item.carbon == "low" ? "leaf.fill" : "exclamationmark.triangle.fill"
    }

    private var carbonColor: Color {
        switch item.carbon {
        case "low": return .campusMint
        case "medium": return .berkeleyGold
        case "high": return .poppy
        default: return .secondary
        }
    }

    private var carbonText: String {
        if let co2 = item.carbonKgCo2 {
            return "\(item.carbon?.capitalized ?? "Estimated") - \(oneDecimal(co2)) kg CO2"
        }
        return item.carbon?.capitalized ?? "Not listed"
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
                .monospacedDigit()
        }
    }

    private func displayLocation(_ location: String) -> String {
        switch location {
        case "Cafe3": return "Cafe 3"
        case "ClarkKerr": return "Clark Kerr"
        default: return location
        }
    }

    private func oneDecimal(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }
}

private struct HeroBadge: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.18), in: Capsule())
    }
}
