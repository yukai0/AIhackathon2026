import SwiftUI

private enum AppTab: Hashable {
    case today
    case menu
    case profile
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .today
    @State private var hasBypassedLogin = false

    var body: some View {
        Group {
            if hasBypassedLogin {
                mainTabs
            } else {
                SignInBypassView {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                        hasBypassedLogin = true
                    }
                }
            }
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }
                .tag(AppTab.today)
            MenuBrowserView()
                .tabItem {
                    Label("Menu", systemImage: "fork.knife")
                }
                .tag(AppTab.menu)
            ProfileView {
                withAnimation {
                    selectedTab = .today
                }
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(AppTab.profile)
        }
        .tint(.berkeleyBlue)
    }
}

private struct SignInBypassView: View {
    @State private var isSigningIn = false
    @State private var animate = false
    let onBypass: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.berkeleyBlue,
                    Color(red: 0.02, green: 0.42, blue: 0.52),
                    Color(red: 0.96, green: 0.47, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { proxy in
                ZStack {
                    LoginShape(color: .berkeleyGold, size: 150, position: CGPoint(x: proxy.size.width * 0.18, y: proxy.size.height * 0.16), animate: animate)
                    LoginShape(color: .green, size: 92, position: CGPoint(x: proxy.size.width * 0.84, y: proxy.size.height * 0.24), animate: animate, delay: 0.2)
                    LoginShape(color: .white, size: 118, position: CGPoint(x: proxy.size.width * 0.15, y: proxy.size.height * 0.78), animate: animate, delay: 0.35)
                    LoginShape(color: .berkeleyGold, size: 72, position: CGPoint(x: proxy.size.width * 0.82, y: proxy.size.height * 0.82), animate: animate, delay: 0.1)

                    LoginSymbol(symbol: "fork.knife.circle.fill", color: .berkeleyGold, position: CGPoint(x: proxy.size.width * 0.24, y: proxy.size.height * 0.33), animate: animate)
                    LoginSymbol(symbol: "person.crop.circle.badge.checkmark", color: .white, position: CGPoint(x: proxy.size.width * 0.73, y: proxy.size.height * 0.36), animate: animate, delay: 0.2)
                    LoginSymbol(symbol: "leaf.fill", color: .green, position: CGPoint(x: proxy.size.width * 0.23, y: proxy.size.height * 0.63), animate: animate, delay: 0.35)
                    LoginSymbol(symbol: "sparkles", color: .white, position: CGPoint(x: proxy.size.width * 0.76, y: proxy.size.height * 0.64), animate: animate, delay: 0.1)
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer(minLength: 46)

                VStack(spacing: 18) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 34)
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 138, height: 138)
                            .rotationEffect(.degrees(animate ? 8 : -8))
                        RoundedRectangle(cornerRadius: 26)
                            .stroke(Color.white.opacity(0.42), lineWidth: 2)
                            .frame(width: 106, height: 106)
                            .rotationEffect(.degrees(animate ? -14 : 14))
                        Image(systemName: "bolt.heart.fill")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(animate ? 1.06 : 0.94)
                    }
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: animate)

                    VStack(spacing: 8) {
                        Text("BearFuel")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Sign in to personalize your dining plan.")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.86))
                            .multilineTextAlignment(.center)
                    }
                }

                VStack(spacing: 12) {
                    SignInButton(
                        title: isSigningIn ? "Signing in..." : "Continue with Apple",
                        symbol: "apple.logo",
                        foreground: .black,
                        background: .white,
                        isLoading: isSigningIn,
                        action: bypassSignIn
                    )
                    SignInButton(
                        title: "Continue with Berkeley",
                        symbol: "graduationcap.fill",
                        foreground: .white,
                        background: Color.berkeleyBlue.opacity(0.86),
                        isLoading: false,
                        action: bypassSignIn
                    )
                    Button(action: bypassSignIn) {
                        Text("Continue as Guest")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSigningIn)
                }
                .padding(18)
                .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 28))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )

                HStack(spacing: 10) {
                    LoginBadge(symbol: "lock.fill", text: "demo auth")
                    LoginBadge(symbol: "sparkles", text: "AI ready")
                }

                Spacer(minLength: 34)
            }
            .padding(.horizontal, 26)
        }
        .onAppear {
            animate = true
        }
    }

    private func bypassSignIn() {
        guard !isSigningIn else { return }
        isSigningIn = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            onBypass()
        }
    }
}

private struct SignInButton: View {
    let title: String
    let symbol: String
    let foreground: Color
    let background: Color
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(foreground)
                } else {
                    Image(systemName: symbol)
                        .font(.system(size: 17, weight: .semibold))
                }
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(background, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

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
            .animation(.easeInOut(duration: 1.8).delay(delay).repeatForever(autoreverses: true), value: animate)
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
            .animation(.easeInOut(duration: 1.6).delay(delay).repeatForever(autoreverses: true), value: animate)
    }
}
