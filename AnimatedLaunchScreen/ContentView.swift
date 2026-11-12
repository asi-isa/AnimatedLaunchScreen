import SwiftUI
import AuthenticationServices

struct ContentView: View {
    @AppStorage("isOnboardingCompleted") private var isOnboardingCompleted = false
    
    var body: some View {
        Text("Hello, world!")
            .padding()
            .splashScreen(config: .init(), showOnBoarding: !isOnboardingCompleted) {
                OnBoardingView()
            }
    }
}

/// OnBoardingView
struct OnBoardingView: View {
    @AppStorage("isOnboardingCompleted") private var isOnboardingCompleted = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Discover your favourite\nApple Products")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            
            SignInWithAppleButton { _ in
                //
            } onCompletion: { _ in
                dismiss()
                isOnboardingCompleted = true
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .clipShape(.capsule)
            
            Text("By continuing, you agree to our\nTerms of Service and Privacy Policy")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary.secondary)
            
        }
        .padding(.horizontal, 5)
        .padding(15)
    }
}

#Preview {
    ContentView()
}

