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
        FlowLayout(spacing: compact ? 6 : 8) {
            MacroChip(icon: "flame.fill",
                      value: "\(Int(totals.kcal)) kcal",
                      color: .orange)
            MacroChip(icon: "bolt.fill",
                      value: "\(Int(totals.proteinG))g protein",
                      color: .berkeleyBlue)
            MacroChip(icon: "leaf.fill",
                      value: "\(Int(totals.carbG))g carbs",
                      color: .green)
            MacroChip(icon: "drop.fill",
                      value: "\(Int(totals.fatG))g fat",
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
        case "vegan": return "Vegan"
        case "vegetarian": return "Vegetarian"
        case "halal": return "Halal"
        case "kosher": return "Kosher"
        default: return flag.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    private var icon: String {
        switch flag {
        case "vegan", "vegetarian": return "leaf.fill"
        case "halal", "kosher": return "checkmark.seal.fill"
        default: return "tag.fill"
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
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(label)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .cornerRadius(8)
    }
}

// MARK: - Food avatar

struct FoodAvatar: View {
    let item: MenuItem

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(color)
            .frame(width: 42, height: 42)
            .background(color.opacity(0.14))
            .clipShape(Circle())
            .accessibilityHidden(true)
    }

    private var symbol: String {
        let text = "\(item.name) \(item.station)".lowercased()
        if text.contains("salad") || text.contains("greens") || text.contains("bok choy") {
            return "leaf.fill"
        }
        if text.contains("chicken") || text.contains("beef") || text.contains("egg") || text.contains("tofu") {
            return "fork.knife"
        }
        if text.contains("rice") || text.contains("quinoa") || text.contains("pasta") {
            return "takeoutbag.and.cup.and.straw.fill"
        }
        if text.contains("bagel") || text.contains("roll") {
            return "circle.grid.cross.fill"
        }
        if text.contains("yogurt") {
            return "cup.and.saucer.fill"
        }
        if text.contains("almond") || text.contains("seed") {
            return "circle.hexagongrid.fill"
        }
        return "fork.knife.circle.fill"
    }

    private var color: Color {
        let text = "\(item.name) \(item.station)".lowercased()
        if text.contains("salad") || text.contains("greens") || text.contains("bok choy") {
            return .green
        }
        if text.contains("chicken") || text.contains("beef") || text.contains("egg") || text.contains("tofu") {
            return .berkeleyBlue
        }
        if text.contains("rice") || text.contains("quinoa") || text.contains("pasta") || text.contains("bagel") || text.contains("roll") {
            return .orange
        }
        if text.contains("yogurt") {
            return .purple
        }
        return .berkeleyGold
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

// MARK: - Vibrant gradients

extension LinearGradient {
    // Vibrant hero gradient (sky blue → teal)
    static let berkeleyVibrant = LinearGradient(
        colors: [Color(red: 0.10, green: 0.48, blue: 0.92),
                 Color(red: 0.02, green: 0.65, blue: 0.80)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

func mealGradient(for label: String) -> LinearGradient {
    switch label.lowercased() {
    case "breakfast", "brunch":
        return LinearGradient(
            colors: [Color(red:1.00,green:0.58,blue:0.00), Color(red:1.00,green:0.76,blue:0.15)],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    case "dinner":
        return LinearGradient(
            colors: [Color(red:0.50,green:0.20,blue:0.88), Color(red:0.68,green:0.42,blue:0.98)],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    default: // lunch and anything else
        return LinearGradient(
            colors: [Color(red:0.10,green:0.48,blue:0.92), Color(red:0.02,green:0.65,blue:0.80)],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct GradientCardView<Content: View>: View {
    var gradient: LinearGradient = .berkeleyVibrant
    @ViewBuilder let content: () -> Content
    var body: some View {
        content()
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color(red:0.10,green:0.48,blue:0.92).opacity(0.30), radius: 14, x: 0, y: 7)
    }
}

// MARK: - Animated counter

struct AnimatedCounter: View {
    let value: Double
    let format: String
    var color: Color = .primary
    @State private var displayed: Double = 0

    var body: some View {
        Text(String(format: format, displayed))
            .foregroundColor(color)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) { displayed = value }
            }
            .onChange(of: value) { _, new in
                withAnimation(.easeOut(duration: 0.7)) { displayed = new }
            }
    }
}

// MARK: - Gradient progress ring

struct GradientProgressRing: View {
    let current: Double
    let target: Double
    let colors: [Color]
    var lineWidth: CGFloat = 12

    var body: some View {
        let fraction = min(current / max(target, 1), 1.0)
        ZStack {
            Circle()
                .stroke(colors[0].opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    AngularGradient(
                        colors: colors,
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(360 * fraction - 90)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.9, dampingFraction: 0.7), value: fraction)
        }
    }
}

// MARK: - Card entrance animation

struct CardEntrance: ViewModifier {
    let delay: Double
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 28)
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.78).delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func cardEntrance(delay: Double = 0) -> some View {
        modifier(CardEntrance(delay: delay))
    }
}

// MARK: - Simple flow layout for chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width, currentX > 0 {
                currentY += rowHeight + spacing
                currentX = 0
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: currentY + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX, currentX > bounds.minX {
                currentY += rowHeight + spacing
                currentX = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
