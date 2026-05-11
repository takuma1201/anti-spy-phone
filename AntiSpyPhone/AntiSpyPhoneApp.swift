import SwiftUI
import LocalAuthentication

@main
struct AntiSpyPhoneApp: App {
    @State private var isAuthenticated = false
    @State private var authError: String?

    var body: some Scene {
        WindowGroup {
            if isAuthenticated {
                ContentView()
                    .preferredColorScheme(.dark)
            } else {
                AuthGateView(authError: authError, onRetry: authenticate)
                    .preferredColorScheme(.dark)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 740)
        .windowResizability(.contentMinSize)
    }

    private func authenticate() {
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &err) else {
            isAuthenticated = true
            return
        }
        ctx.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "AntiSpy Phone へのアクセスを認証"
        ) { success, error in
            DispatchQueue.main.async {
                if success {
                    withAnimation(.easeOut(duration: 0.25)) { isAuthenticated = true }
                } else {
                    authError = error?.localizedDescription
                }
            }
        }
    }
}

// MARK: - Auth gate

struct AuthGateView: View {
    let authError: String?
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            // OLED black base
            Color.ndBlack.ignoresSafeArea()

            // Dot-grid background — full canvas
            DotGridBackground(spacing: 16, dotSize: 1, opacity: 0.10)
                .ignoresSafeArea()

            // Radial fade to hide dots near center
            RadialGradient(
                colors: [Color.ndBlack, Color.ndBlack.opacity(0)],
                center: .center,
                startRadius: 120,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // PRIMARY — product name in Doto dot-matrix
                VStack(spacing: 12) {
                    Text("ANTISPY")
                        .font(NFont.displayXL)
                        .foregroundStyle(Color.ndTextDisplay)
                        .tracking(-2)

                    Text("PHONE")
                        .font(NFont.displayMD)
                        .foregroundStyle(Color.ndTextSecondary)
                        .tracking(8)
                }

                Spacer().frame(height: 64)

                // SECONDARY — instruction
                Text("Touch ID またはログインパスワードで認証")
                    .font(NFont.body)
                    .foregroundStyle(Color.ndTextPrimary)

                Spacer().frame(height: 8)

                // TERTIARY — system label
                Text("AUTHENTICATE TO CONTINUE")
                    .font(NFont.label)
                    .foregroundStyle(Color.ndTextDisabled)
                    .tracking(2)

                Spacer().frame(height: 48)

                // Error state — accent red inline, no banner
                if let error = authError {
                    VStack(spacing: 12) {
                        Text("[ ERROR: \(error.uppercased()) ]")
                            .font(NFont.label)
                            .foregroundStyle(Color.ndAccent)
                            .tracking(1)

                        Button("RETRY", action: onRetry)
                            .font(NFont.label)
                            .foregroundStyle(Color.ndBlack)
                            .tracking(2)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.ndTextDisplay)
                            .clipShape(Capsule())
                            .pointingHandCursor()
                    }
                }

                // Red signal dot — the single accent moment
                Spacer().frame(height: 48)
                Circle()
                    .fill(Color.ndAccent)
                    .frame(width: 6, height: 6)

                Spacer()
            }
        }
        .frame(minWidth: 960, minHeight: 640)
        .onAppear(perform: onRetry)
    }
}
