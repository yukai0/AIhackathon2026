import SwiftUI

// MARK: - Berkeley theme

enum BerkeleyTheme {
    static let navy = Color(red: 0.00, green: 0.15, blue: 0.30)
    static let blue = Color(red: 0.00, green: 0.23, blue: 0.46)
    static let brightBlue = Color(red: 0.08, green: 0.45, blue: 0.86)
    static let gold = Color(red: 1.00, green: 0.70, blue: 0.08)
    static let warmGold = Color(red: 1.00, green: 0.55, blue: 0.12)
    static let bay = Color(red: 0.02, green: 0.61, blue: 0.78)
    static let mint = Color(red: 0.10, green: 0.72, blue: 0.47)
    static let coral = Color(red: 0.96, green: 0.36, blue: 0.25)
    static let violet = Color(red: 0.45, green: 0.26, blue: 0.82)
    static let ink = Color(red: 0.07, green: 0.09, blue: 0.13)

    static let screenGradient = LinearGradient(
        colors: [
            Color(.systemBackground),
            Color(red: 0.93, green: 0.97, blue: 1.00),
            Color(red: 1.00, green: 0.97, blue: 0.90)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [navy, blue, bay],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldGradient = LinearGradient(
        colors: [gold, warmGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let vibrantGradient = LinearGradient(
        colors: [brightBlue, bay, mint],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let judgeGradient = LinearGradient(
        colors: [navy, brightBlue, gold, coral],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func accent(for index: Int) -> Color {
        [brightBlue, gold, mint, coral, violet, bay][abs(index) % 6]
    }

    static func mealGradient(for label: String) -> LinearGradient {
        switch label.lowercased() {
        case "breakfast", "brunch":
            return LinearGradient(colors: [warmGold, gold], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "dinner":
            return LinearGradient(colors: [violet, blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [brightBlue, bay], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Colors

extension Color {
    static let berkeleyBlue = BerkeleyTheme.blue
    static let berkeleyGold = BerkeleyTheme.gold
    static let bayBlue = BerkeleyTheme.bay
    static let campusMint = BerkeleyTheme.mint
    static let poppy = BerkeleyTheme.coral
    static let cardBackground = Color(.systemBackground)
    static let subtleBackground = Color(.secondarySystemBackground)
    static let appGroupedBackground = Color(red: 0.95, green: 0.97, blue: 0.99)
}

// MARK: - Corner radii

enum CornerRadius {
    static let card: CGFloat = 20
    static let chip: CGFloat = 16
    static let button: CGFloat = 16
    static let panel: CGFloat = 28
}

// MARK: - Shadows

extension View {
    func cardShadow() -> some View {
        self.shadow(color: BerkeleyTheme.blue.opacity(0.10), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Card container

struct CardView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
            )
            .cardShadow()
    }
}

struct BerkeleyCard<Content: View>: View {
    var padding: CGFloat = 16
    var radius: CGFloat = CornerRadius.card
    var content: Content

    init(padding: CGFloat = 16, radius: CGFloat = CornerRadius.card, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.8), Color.berkeleyBlue.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: BerkeleyTheme.blue.opacity(0.10), radius: 18, x: 0, y: 9)
    }
}

// MARK: - Screen backdrop

struct CampusBackdrop: View {
    var intensity: Double = 1
    var animated = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase = false

    var body: some View {
        ZStack {
            BerkeleyTheme.screenGradient
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                ZStack {
                    CampusRibbon(
                        color: BerkeleyTheme.gold,
                        width: width * 0.74,
                        height: 72,
                        rotation: -18,
                        x: width * 0.25,
                        y: height * 0.12,
                        phase: phase,
                        intensity: intensity
                    )
                    CampusRibbon(
                        color: BerkeleyTheme.bay,
                        width: width * 0.62,
                        height: 54,
                        rotation: 20,
                        x: width * 0.82,
                        y: height * 0.30,
                        phase: phase,
                        intensity: intensity * 0.8
                    )
                    CampusRibbon(
                        color: BerkeleyTheme.coral,
                        width: width * 0.52,
                        height: 48,
                        rotation: -24,
                        x: width * 0.06,
                        y: height * 0.74,
                        phase: phase,
                        intensity: intensity * 0.75
                    )
                    CampusRibbon(
                        color: BerkeleyTheme.mint,
                        width: width * 0.68,
                        height: 58,
                        rotation: 16,
                        x: width * 0.84,
                        y: height * 0.86,
                        phase: phase,
                        intensity: intensity * 0.65
                    )
                }
                .blur(radius: 0.2)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            guard animated, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true)) {
                phase = true
            }
        }
    }
}

private struct CampusRibbon: View {
    let color: Color
    let width: CGFloat
    let height: CGFloat
    let rotation: Double
    let x: CGFloat
    let y: CGFloat
    let phase: Bool
    let intensity: Double

    var body: some View {
        RoundedRectangle(cornerRadius: height * 0.34, style: .continuous)
            .fill(color.opacity(0.12 * intensity))
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: height * 0.34, style: .continuous)
                    .stroke(color.opacity(0.12 * intensity), lineWidth: 1)
            )
            .rotationEffect(.degrees(phase ? rotation + 4 : rotation - 4))
            .position(x: x, y: y + (phase ? -10 : 10))
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
        .padding(.vertical, 6)
        .background(color.opacity(0.13), in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.14), lineWidth: 1))
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

struct MetricPill: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.primary)
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Color(.systemBackground).opacity(0.72), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct BerkeleySectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.berkeleyBlue)
                    .frame(width: 28, height: 28)
                    .background(Color.berkeleyGold.opacity(0.22), in: RoundedRectangle(cornerRadius: 9))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
    }
}

struct PrimaryGradientButton: View {
    let title: String
    var icon: String = "sparkles"
    var gradient: LinearGradient = BerkeleyTheme.heroGradient
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                Text(title)
                    .font(.headline.weight(.semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(gradient, in: RoundedRectangle(cornerRadius: CornerRadius.button))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.button)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: BerkeleyTheme.blue.opacity(0.24), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

struct SelectionChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    var color: Color = .berkeleyBlue
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                }
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color(.systemBackground).opacity(0.82), in: Capsule())
            .overlay(Capsule().stroke(isSelected ? color.opacity(0.18) : color.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
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
        .background(color.opacity(0.12), in: Capsule())
    }
}

// MARK: - Food avatar

struct FoodAvatar: View {
    let item: MenuItem

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [color.opacity(0.95), color.opacity(0.52)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color.white.opacity(0.38), lineWidth: 1)
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: 46, height: 46)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .shadow(color: color.opacity(0.26), radius: 8, x: 0, y: 4)
        .accessibilityHidden(true)
    }

    private var symbol: String {
        let text = "\(item.name) \(item.station)".lowercased()
        if text.contains("salad") || text.contains("greens") || text.contains("bok choy") {
            return "leaf.fill"
        }
        if text.contains("cake") || text.contains("cookie") || text.contains("dessert") {
            return "birthday.cake.fill"
        }
        if text.contains("fruit") || text.contains("apple") || text.contains("berry") {
            return "apple.logo"
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
            return BerkeleyTheme.mint
        }
        if text.contains("cake") || text.contains("cookie") || text.contains("dessert") {
            return BerkeleyTheme.coral
        }
        if text.contains("fruit") || text.contains("apple") || text.contains("berry") {
            return .red
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
    static let berkeleyVibrant = BerkeleyTheme.vibrantGradient
    static let berkeleyHero = BerkeleyTheme.heroGradient
    static let berkeleyGoldRush = BerkeleyTheme.goldGradient
}

func mealGradient(for label: String) -> LinearGradient {
    BerkeleyTheme.mealGradient(for: label)
}

struct GradientCardView<Content: View>: View {
    var gradient: LinearGradient = .berkeleyHero
    @ViewBuilder let content: () -> Content
    var body: some View {
        content()
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.panel, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.panel, style: .continuous)
                    .stroke(Color.white.opacity(0.20), lineWidth: 1)
            )
            .shadow(color: BerkeleyTheme.blue.opacity(0.28), radius: 18, x: 0, y: 10)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: reduceMotion ? 0 : (appeared ? 0 : 28))
            .onAppear {
                guard !reduceMotion else {
                    appeared = true
                    return
                }
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
