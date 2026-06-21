import SwiftUI

private enum AppTab: Hashable {
    case today
    case menu
    case profile
}

struct ContentView: View {
    @AppStorage("bearfuel.isLoggedIn") private var isLoggedIn = false
    @State private var selectedTab: AppTab = .today

    var body: some View {
        Group {
            if isLoggedIn {
                mainTabs
            } else {
                LoginView { isLoggedIn = true }
            }
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
                .tag(AppTab.today)
            MenuBrowserView()
                .tabItem { Label("Menu", systemImage: "fork.knife") }
                .tag(AppTab.menu)
            ProfileView(
                onBodyStatsEntered: {
                    withAnimation { selectedTab = .today }
                },
                onLogout: {
                    withAnimation {
                        selectedTab = .today
                        isLoggedIn = false
                    }
                }
            )
            .tabItem { Label("Profile", systemImage: "person.fill") }
            .tag(AppTab.profile)
        }
        .tint(.berkeleyBlue)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color(.systemBackground), for: .tabBar)
    }
}

// MARK: - LoginView

private struct LoginView: View {
    let onLogin: () -> Void

    @State private var username = ""
    @State private var password = ""
    @State private var animate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            CampusBackdrop(intensity: 1.8)
            BerkeleyTheme.judgeGradient
                .opacity(0.92)
                .ignoresSafeArea()

            GeometryReader { proxy in
                ZStack {
                    LoginShape(color: .berkeleyGold, size: 168, position: CGPoint(x: proxy.size.width * 0.16, y: proxy.size.height * 0.15), animate: animate && !reduceMotion)
                    LoginShape(color: .campusMint, size: 104, position: CGPoint(x: proxy.size.width * 0.84, y: proxy.size.height * 0.25), animate: animate && !reduceMotion, delay: 0.2)
                    LoginShape(color: .white, size: 126, position: CGPoint(x: proxy.size.width * 0.15, y: proxy.size.height * 0.78), animate: animate && !reduceMotion, delay: 0.35)
                    LoginShape(color: .poppy, size: 92, position: CGPoint(x: proxy.size.width * 0.83, y: proxy.size.height * 0.82), animate: animate && !reduceMotion, delay: 0.1)
                    LoginSymbol(symbol: "graduationcap.fill", color: .berkeleyGold, position: CGPoint(x: proxy.size.width * 0.24, y: proxy.size.height * 0.33), animate: animate && !reduceMotion)
                    LoginSymbol(symbol: "fork.knife", color: .white, position: CGPoint(x: proxy.size.width * 0.24, y: proxy.size.height * 0.63), animate: animate && !reduceMotion, delay: 0.35)
                    LoginSymbol(symbol: "chart.line.uptrend.xyaxis", color: .campusMint, position: CGPoint(x: proxy.size.width * 0.76, y: proxy.size.height * 0.64), animate: animate && !reduceMotion, delay: 0.1)
                }
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 52)

                    VStack(spacing: 18) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 34, style: .continuous)
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 142, height: 142)
                                .rotationEffect(.degrees(animate && !reduceMotion ? 8 : -8))
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .stroke(Color.white.opacity(0.42), lineWidth: 2)
                                .frame(width: 108, height: 108)
                                .rotationEffect(.degrees(animate && !reduceMotion ? -14 : 14))
                            Image(systemName: "bolt.heart.fill")
                                .font(.system(size: 46, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(animate && !reduceMotion ? 1.06 : 1)
                        }
                        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: animate)

                        VStack(spacing: 8) {
                            Text("BearFuel")
                                .font(.system(size: 42, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            Text("AI-powered Berkeley dining, personalized for your day.")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.88))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }

                    VStack(spacing: 14) {
                        VStack(spacing: 10) {
                            TextField("CalNet ID", text: $username)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .textContentType(.username)
                                .padding(14)
                                .background(Color.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                                .foregroundColor(.white)
                                .tint(.white)

                            SecureField("Password", text: $password)
                                .textContentType(.password)
                                .padding(14)
                                .background(Color.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                                .foregroundColor(.white)
                                .tint(.white)
                                .onSubmit { attemptLogin() }
                        }

                        Button(action: attemptLogin) {
                            HStack(spacing: 10) {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Sign In")
                                    .font(.headline.weight(.semibold))
                            }
                            .foregroundColor(.berkeleyBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Button(action: attemptLogin) {
                            Text("Continue Demo")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(18)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )

                    HStack(spacing: 10) {
                        LoginBadge(symbol: "graduationcap.fill", text: "Berkeley")
                        LoginBadge(symbol: "sparkles", text: "AI ready")
                        LoginBadge(symbol: "fork.knife", text: "Dining")
                    }

                    Spacer(minLength: 36)
                }
                .padding(.horizontal, 26)
            }
        }
        .onAppear { animate = true }
    }

    private func attemptLogin() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
            onLogin()
        }
    }
}

// MARK: - Shared helpers

private struct LoginBadge: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
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

private struct LoginShape: View {
    let color: Color
    let size: CGFloat
    let position: CGPoint
    let animate: Bool
    var delay: Double = 0

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.24)
            .fill(color.opacity(0.2))
            .frame(width: size, height: size * 0.64)
            .rotationEffect(.degrees(animate ? 18 : -18))
            .position(position)
            .offset(y: animate ? -12 : 12)
            .animation(animate ? .easeInOut(duration: 1.8).delay(delay).repeatForever(autoreverses: true) : .default, value: animate)
    }
}

private struct LoginSymbol: View {
    let symbol: String
    let color: Color
    let position: CGPoint
    let animate: Bool
    var delay: Double = 0

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 26, weight: .bold))
            .foregroundColor(color.opacity(0.92))
            .padding(14)
            .background(Color.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 16))
            .position(position)
            .offset(y: animate ? 10 : -10)
            .animation(animate ? .easeInOut(duration: 1.6).delay(delay).repeatForever(autoreverses: true) : .default, value: animate)
    }
}
