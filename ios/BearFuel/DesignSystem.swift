import SwiftUI

// MARK: - Colors

extension Color {
    static let berkeleyBlue = Color(red: 0, green: 50/255, blue: 98/255)
    static let berkeleyGold = Color(red: 253/255, green: 181/255, blue: 21/255)
    static let cardBackground = Color(.systemBackground)
    static let subtleBackground = Color(.secondarySystemBackground)
}

// MARK: - Corner radii

enum CornerRadius {
    static let card: CGFloat = 16
    static let chip: CGFloat = 20
    static let button: CGFloat = 14
}

// MARK: - Shadows

extension View {
    func cardShadow() -> some View {
        self.shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Card container

struct CardView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.card)
            .cardShadow()
    }
}

// MARK: - Macro chip

struct MacroChip: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .cornerRadius(CornerRadius.chip)
    }
}

// MARK: - Macro row (four chips)

struct MacroRow: View {
    let totals: MacroTotals
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 6 : 8) {
            MacroChip(icon: "flame.fill",
                      value: "\(Int(totals.kcal)) kcal",
                      color: .orange)
            MacroChip(icon: "bolt.fill",
                      value: "\(Int(totals.proteinG))g P",
                      color: .berkeleyBlue)
            MacroChip(icon: "leaf.fill",
                      value: "\(Int(totals.carbG))g C",
                      color: .green)
            MacroChip(icon: "drop.fill",
                      value: "\(Int(totals.fatG))g F",
                      color: .berkeleyGold)
        }
    }
}

// MARK: - Progress ring

struct ProgressRing: View {
    let current: Double
    let target: Double
    let color: Color
    var lineWidth: CGFloat = 10

    private var fraction: Double { min(current / max(target, 1), 1.2) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: fraction)
        }
    }
}

// MARK: - Diet flag badge

struct DietBadge: View {
    let flag: String

    private var label: String {
        switch flag {
        case "vegan": return "VE"
        case "vegetarian": return "V"
        case "halal": return "H"
        case "kosher": return "K"
        default: return flag.prefix(2).uppercased()
        }
    }
    private var color: Color {
        switch flag {
        case "vegan": return .green
        case "vegetarian": return .mint
        case "halal": return .berkeleyBlue
        case "kosher": return .purple
        default: return .gray
        }
    }

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .cornerRadius(6)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
            .padding(.horizontal)
    }
}
