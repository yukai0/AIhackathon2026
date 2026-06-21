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
            ProfileView {
                withAnimation { selectedTab = .today }
            }
            .tabItem { Label("Profile", systemImage: "person.fill") }
            .tag(AppTab.profile)
        }
        .tint(.berkeleyBlue)
    }
}

// MARK: - LoginView

private struct LoginView: View {
    let onLogin: () -> Void

    @State private var username = ""
    @State private var password = ""
    @State private var shake = false
    @State private var errorMsg: String? = nil
    @State private var animate = false

    private let correctUsername = "admin"
    private let correctPassword = "calhacks123"

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

                    VStack(spacing: 6) {
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
                    VStack(spacing: 10) {
                        TextField("Username", text: $username)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding(14)
                            .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                            .foregroundColor(.white)
                            .tint(.white)

                        SecureField("Password", text: $password)
                            .padding(14)
                            .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                            .foregroundColor(.white)
                            .tint(.white)
                            .onSubmit { attemptLogin() }
                    }

                    if let errorMsg {
                        Text(errorMsg)
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.9))
                            .padding(.horizontal, 4)
                    }

                    Button(action: attemptLogin) {
                        Text("Sign In")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.berkeleyBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .offset(x: shake ? -8 : 0)
                }
                .padding(18)
                .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 28))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )

                HStack(spacing: 10) {
                    LoginBadge(symbol: "lock.fill", text: "secure login")
                    LoginBadge(symbol: "sparkles", text: "AI ready")
                }

                Spacer(minLength: 34)
            }
            .padding(.horizontal, 26)
        }
        .onAppear { animate = true }
    }

    private func attemptLogin() {
        if username == correctUsername && password == correctPassword {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                onLogin()
            }
        } else {
            errorMsg = "Incorrect username or password."
            withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) {
                shake = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { shake = false }
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
