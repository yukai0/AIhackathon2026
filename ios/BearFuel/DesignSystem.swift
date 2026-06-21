import SwiftUI

// MARK: - Colors

extension Color {
    static let berkeleyBlue = Color(red: 0, green: 50/255, blue: 98/255)
    static let berkeleyGold = Color(red: 253/255, green: 181/255, blue: 21/255)
    static let cardBackground = Color(.systemBackground)
    static let subtleBackground = Color(.secondarySystemBackground)
}

// MARK: - Gradients

extension LinearGradient {
    static let berkeleyHero = LinearGradient(
        colors: [Color.berkeleyBlue, Color(red: 0.04, green: 0.38, blue: 0.52)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let berkeleyGold = LinearGradient(
        colors: [Color(red: 1.0, green: 0.72, blue: 0.08), Color.berkeleyGold],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Meal gradient helper

func mealGradient(for label: String) -> LinearGradient {
    switch label.lowercased() {
    case "breakfast", "brunch":
        return LinearGradient(colors: [Color(red: 1.0, green: 0.55, blue: 0.0), Color.berkeleyGold], startPoint: .topLeading, endPoint: .bottomTrailing)
    case "lunch":
        return LinearGradient(colors: [Color.berkeleyBlue, Color(red: 0.04, green: 0.45, blue: 0.60)], startPoint: .topLeading, endPoint: .bottomTrailing)
    case "dinner":
        return LinearGradient(colors: [Color(red: 0.25, green: 0.05, blue: 0.45), Color(red: 0.45, green: 0.15, blue: 0.65)], startPoint: .topLeading, endPoint: .bottomTrailing)
    default:
        return LinearGradient(colors: [Color.berkeleyBlue, Color(red: 0.04, green: 0.45, blue: 0.60)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Corner radii

enum CornerRadius {
    static let card: CGFloat = 20
    static let chip: CGFloat = 20
    static let button: CGFloat = 16
}

// MARK: - Shadows

extension View {
    func cardShadow() -> some View {
        self.shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Card entrance animation

struct CardEntrance: ViewModifier {
    let delay: Double
    @State private var appeared = false
    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 44)
            .scaleEffect(appeared ? 1 : 0.96)
            .onAppear {
                withAnimation(.spring(response: 0.65, dampingFraction: 0.75).delay(delay)) {
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

// MARK: - Shimmer effect

struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1.5
    func body(content: Content) -> some View {
        content.overlay(
            GeometryReader { geo in
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.25), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geo.size.width)
                .offset(x: phase * geo.size.width)
            }
            .clipped()
            .allowsHitTesting(false)
        )
        .onAppear {
            withAnimation(.linear(duration: 2.8).delay(0.4).repeatForever(autoreverses: false)) {
                phase = 1.5
            }
        }
    }
}

extension View {
    func shimmer() -> some View { modifier(Shimmer()) }
}

// MARK: - Card container (liquid glass)

struct CardView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .background(Color.white.opacity(0.13))
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.5), Color.white.opacity(0.10)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
            .cornerRadius(CornerRadius.card)
            .shadow(color: .black.opacity(0.30), radius: 18, x: 0, y: 8)
    }
}

// MARK: - Gradient card container

struct GradientCardView<Content: View>: View {
    let gradient: LinearGradient
    let content: Content
    init(gradient: LinearGradient = .berkeleyHero, @ViewBuilder content: () -> Content) {
        self.gradient = gradient
        self.content = content()
    }
    var body: some View {
        content
            .background(gradient)
            .cornerRadius(20)
            .shadow(color: Color.berkeleyBlue.opacity(0.35), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Animated counter

struct AnimatedCounter: View {
    let value: Double
    let format: String
    let color: Color
    @State private var displayed: Double = 0

    var body: some View {
        Text(String(format: format, displayed))
            .onAppear { withAnimation(.easeOut(duration: 1.0)) { displayed = value } }
            .onChange(of: value) { _, new in withAnimation(.easeOut(duration: 0.8)) { displayed = new } }
            .foregroundColor(color)
    }
}

// MARK: - Gradient progress ring

struct GradientProgressRing: View {
    let current: Double
    let target: Double
    let colors: [Color]
    var lineWidth: CGFloat = 12
    var animDelay: Double = 0

    @State private var drawn: Double = 0

    var body: some View {
        let target_fraction = min(current / max(target, 1), 1.0)
        ZStack {
            Circle()
                .stroke(colors[0].opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: drawn)
                .stroke(
                    AngularGradient(
                        colors: colors,
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(360 * drawn - 90)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .onAppear {
            withAnimation(.spring(response: 1.1, dampingFraction: 0.72).delay(animDelay)) {
                drawn = target_fraction
            }
        }
        .onChange(of: target_fraction) { _, new in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                drawn = new
            }
        }
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

// MARK: - Progress ring (kept for backward compatibility)

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

// MARK: - Animated Berkeley background

struct BerkeleyBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // Berkeley Blue gradient base — medium brightness so it reads clearly as blue
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.28, blue: 0.56),
                    Color(red: 0.0, green: 0.20, blue: 0.46),
                    Color(red: 0.0, green: 0.14, blue: 0.36)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Gold glow — top right, clearly visible
            Ellipse()
                .fill(Color.berkeleyGold.opacity(0.55))
                .frame(width: 240, height: 180)
                .blur(radius: 45)
                .offset(x: animate ? 115 : 90, y: animate ? -210 : -180)

            // Teal/cyan accent — mid left
            Circle()
                .fill(Color(red: 0.05, green: 0.65, blue: 0.88).opacity(0.45))
                .frame(width: 200, height: 200)
                .blur(radius: 45)
                .offset(x: animate ? -65 : -90, y: animate ? 90 : 65)

            // Floating shapes (like the loading screen)
            GeometryReader { geo in
                Group {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.berkeleyGold.opacity(0.22))
                        .frame(width: 64, height: 22)
                        .rotationEffect(.degrees(animate ? -18 : -28))
                        .position(x: geo.size.width * 0.15, y: geo.size.height * 0.12)
                        .offset(y: animate ? -10 : 10)
                        .animation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true), value: animate)

                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.13))
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(animate ? 22 : 12))
                        .position(x: geo.size.width * 0.82, y: geo.size.height * 0.18)
                        .offset(y: animate ? 10 : -10)
                        .animation(.easeInOut(duration: 2.8).delay(0.4).repeatForever(autoreverses: true), value: animate)

                    Circle()
                        .fill(Color.berkeleyGold.opacity(0.20))
                        .frame(width: 38, height: 38)
                        .position(x: geo.size.width * 0.88, y: geo.size.height * 0.52)
                        .offset(y: animate ? -12 : 12)
                        .animation(.easeInOut(duration: 3.6).delay(0.2).repeatForever(autoreverses: true), value: animate)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 52, height: 18)
                        .rotationEffect(.degrees(animate ? 30 : 20))
                        .position(x: geo.size.width * 0.12, y: geo.size.height * 0.68)
                        .offset(y: animate ? 10 : -10)
                        .animation(.easeInOut(duration: 2.5).delay(0.7).repeatForever(autoreverses: true), value: animate)
                }
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .onAppear { animate = true }
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
