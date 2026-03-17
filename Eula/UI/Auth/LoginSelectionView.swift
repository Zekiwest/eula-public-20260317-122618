import SwiftUI

struct LoginSelectionView: View {
    @Binding var isAgreementChecked: Bool
    @State private var showToast = false
    
    // Color constants (Figma 1:1)
    private let colorEmailBtn = Color(hexString: "81C8DC")
    private let colorNewBtn = Color(hexString: "ACB1D7")
    private let colorWhite = Color.white
    
    let onLoginSuccess: () -> Void
    let onShowEmailLogin: () -> Void
    let onShowEmailSignUp: () -> Void
    let onShowEULA: () -> Void
    
    var body: some View {
        AppScreen {
            GeometryReader { proxy in
                let bottomInset = max(proxy.safeAreaInsets.bottom, 34)
                let scaleY = proxy.size.height / 812.0
                let agreementCenterY = min(769 * scaleY, proxy.size.height - bottomInset - 9)
                
                ZStack {
                    Image("LoginBackground")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                    
                    VStack {
                        eulaButton
                            .padding(.leading, 16)
                            .padding(.top, 56)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 67) {
                        Image("LoginLogoIcon")
                            .resizable()
                            .frame(width: 88, height: 88)
                            .cornerRadius(20)
                        
                        VStack(spacing: 17) {
                            VStack(spacing: 16) {
                                actionButton(
                                    title: "Sign In with Email",
                                    icon: "LoginEmailIcon_New",
                                    backgroundColor: colorEmailBtn
                                    ,accessibilityIdentifier: "login_email_button"
                                ) {
                                    handleLogin {
                                        onShowEmailLogin()
                                    }
                                }
                            }
                            
                            HStack(spacing: 8) {
                                Text("Don't have an account?")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Button(action: {
                                    onShowEmailSignUp()
                                }) {
                                    Text("Sign Up")
                                        .font(.custom("Notable-Regular", size: 12))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .frame(width: 267)
                    
                    agreementSection
                        .position(x: proxy.size.width / 2, y: agreementCenterY)
                    
                    AuthToastOverlay(
                        isVisible: showToast,
                        message: "Please agree to the Terms of Use and Privacy Policy to continue.",
                        topPadding: 60
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Components
    
    private var eulaButton: some View {
        Button(action: onShowEULA) {
            HStack(spacing: 10) {
                Text("EULA")
                    .font(.custom("Notable-Regular", size: 16))
                    .foregroundColor(.black)
            }
            .padding(10)
            .background(Color.white)
            .cornerRadius(20)
        }
    }
    
    private func actionButton(title: String, icon: String, backgroundColor: Color, accessibilityIdentifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(icon)
                    .resizable()
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.custom("Notable-Regular", size: 14))
            }
            .foregroundColor(.white)
            .frame(width: 267, height: 58)
            .background(backgroundColor)
            .cornerRadius(40)
            .overlay(
                RoundedRectangle(cornerRadius: 40)
                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
            )
            // Figma effect: inset 0px 4px 4px rgba(255,255,255,0.25)
            // Simple overlay-based approximation:
            .overlay(
                RoundedRectangle(cornerRadius: 40)
                    .stroke(Color.white.opacity(0.25), lineWidth: 4)
                    .blur(radius: 4)
                    .mask(RoundedRectangle(cornerRadius: 40).fill(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)))
                    .padding(2)
            )
        }
        .accessibilityIdentifier(accessibilityIdentifier)
    }
    
    private var agreementSection: some View {
        HStack(spacing: 8) {
            // Custom checkbox (16x16, 1px white stroke)
            Button(action: {
                isAgreementChecked.toggle()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white, lineWidth: 1)
                        .frame(width: 16, height: 16)
                    
                    if isAgreementChecked {
                        Image(systemName: "checkmark")
                            .resizable()
                            .font(.system(size: 8, weight: .bold)) // Adjust size to fit
                            .frame(width: 10, height: 10)
                            .foregroundColor(.white)
                    }
                }
            }
            .accessibilityIdentifier("agreement_checkbox")
            
            HStack(spacing: 4) { // Figma gap: 4px
                Text("Agree to")
                    .foregroundColor(.white.opacity(0.8))
                Text("Terms of Use")
                    .foregroundColor(.white)
                Text("and")
                    .foregroundColor(.white.opacity(0.8))
                Text("Privacy Policy")
                    .foregroundColor(.white)
            }
            .font(.system(size: 12)) // Figma: Poppins 12
        }
    }
    
    // MARK: - Logic
    
    private func handleLogin(onSuccess: @escaping () -> Void) {
        if !isAgreementChecked {
            withAnimation {
                showToast = true
            }
            
            // Auto hide after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showToast = false
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onSuccess()
            }
        }
    }
    
    private func handleNewUser() {
        if !isAgreementChecked {
            withAnimation {
                showToast = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showToast = false
                }
            }
        } else {
            let deviceId = DeviceIdentity.deviceID()
            let userId = "guest_\(deviceId)"
            
            AuthManager.shared.saveSession(
                accessToken: "guest_token_\(UUID().uuidString)",
                refreshToken: nil,
                userId: userId,
                email: nil,
                expiresIn: 3600 * 24 * 30
            )
            
            onLoginSuccess()
        }
    }
}

struct LoginSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    LoginSelectionView(isAgreementChecked: .constant(false), onLoginSuccess: {}, onShowEmailLogin: {}, onShowEmailSignUp: {}, onShowEULA: {})
}
    }
}
