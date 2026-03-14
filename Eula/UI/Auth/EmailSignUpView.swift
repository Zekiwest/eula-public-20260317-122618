import SwiftUI
import Foundation

/**
 * [INPUT]: 依赖 AppScreen, AppBackButton, Assets (EULA_BackIcon, SignInDecoration)
 * [OUTPUT]: 对外提供 EmailSignUpView
 * [POS]: UI/Auth 的邮箱登录/注册页与背景视图，被 ContentView 调用
 * [SWIFTUI_STATE]: @State email/password/confirmPassword/showToast/toastMessage; @FocusState focusedField
 * [SWIFTUI_PREVIEWS]: PreviewProvider 默认状态预览
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */
struct EmailSignUpView: View {
    enum AuthMode {
        case login
        case signUp
    }

    enum FocusField {
        case email
        case password
        case confirmPassword
        case verificationCode
    }

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var isSubmitting = false
    @State private var signUpFeedbackMessage: String?
    @State private var verificationCode = ""
    @State private var pendingVerificationEmail: String?
    @FocusState private var focusedField: FocusField?

    let mode: AuthMode
    let onLoginSuccess: () -> Void
    let onForgotPassword: () -> Void
    let onBack: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let scaleX = width / 375.0
            let scaleY = height / 812.0
            let scale = max(scaleX, scaleY)

            AppScreen {
                ZStack {
                    contentLayout(scale: scale)
                }
            }
            .overlay(alignment: .topLeading) {
                backButton()
                    .padding(.leading, 16)
                    .padding(.top, 54)
                    .ignoresSafeArea(.container, edges: .top)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = nil
            }
            .frame(width: width, height: height)
            .overlay {
                AuthToastOverlay(isVisible: showToast, message: toastMessage, topPadding: 60 * scale)
            }
            .onChange(of: focusedField, perform: { newValue in
                if newValue != .email {
                    if !email.isEmpty && !AuthValidator.isEmailValid(email) {
                        AuthToast.show("Please enter a valid email address.", showToast: $showToast, toastMessage: $toastMessage)
                    }
                }
            })
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedField = .email
                }
            }
        }
    }

    private func backButton() -> some View {
        AppBackButton(action: onBack)
    }

    private func contentLayout(scale: CGFloat) -> some View {
        VStack {
            formSection(scale: scale)
                .padding(.top, 74 * scale)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func formSection(scale: CGFloat) -> some View {
        AuthFormSection(title: mode == .signUp ? "Sign Up" : "Sign In", scale: scale) {
                VStack(alignment: .leading, spacing: 16 * scale) {
                    emailField(scale: scale)
                    passwordField(scale: scale)

                    if mode == .signUp {
                        confirmPasswordField(scale: scale)
                        if isAwaitingSignUpVerification {
                            verificationCodeField(scale: scale)
                        }
                    }

                    Button(action: {
                        onForgotPassword()
                    }) {
                        Text("Forgot Password")
                            .font(.custom("Notable-Regular", size: 12 * scale))
                            .kerning(0)
                            .foregroundColor(Color.white.opacity(0.8))
                            .frame(height: 16 * scale, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                signInButton(scale: scale)
                
                if mode == .signUp, let signUpFeedbackMessage {
                    Text(signUpFeedbackMessage)
                        .font(.system(size: 13 * scale, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.88))
                        .multilineTextAlignment(.leading)
                        .frame(width: 332 * scale, alignment: .leading)
                }
        }
    }

    private func emailField(scale: CGFloat) -> some View {
        AuthInputField(
            text: $email,
            placeholder: "Enter Email Address",
            isSecure: false,
            cornerRadius: 33,
            scale: scale,
            contentType: .emailAddress,
            keyboardType: .emailAddress,
            submitLabel: .next,
            onSubmit: {
                focusedField = .password
            },
            focusedField: $focusedField,
            focusEquals: .email
        )
    }

    private func passwordField(scale: CGFloat) -> some View {
        AuthInputField(
            text: $password,
            placeholder: "Enter Password",
            isSecure: true,
            cornerRadius: 43,
            scale: scale,
            contentType: .password,
            keyboardType: .default,
            submitLabel: mode == .signUp ? .next : .go,
            onSubmit: {
                if mode == .signUp {
                    if isAwaitingSignUpVerification {
                        focusedField = .verificationCode
                    } else {
                        focusedField = .confirmPassword
                    }
                } else {
                    handleSubmit()
                }
            },
            focusedField: $focusedField,
            focusEquals: .password
        )
    }

    private func confirmPasswordField(scale: CGFloat) -> some View {
        AuthInputField(
            text: $confirmPassword,
            placeholder: "Confirm Password",
            isSecure: true,
            cornerRadius: 43,
            scale: scale,
            contentType: .password,
            keyboardType: .default,
            submitLabel: .go,
            onSubmit: {
                handleSubmit()
            },
            focusedField: $focusedField,
            focusEquals: .confirmPassword
        )
    }
    
    private func verificationCodeField(scale: CGFloat) -> some View {
        AuthInputField(
            text: $verificationCode,
            placeholder: "Enter Verification Code",
            isSecure: false,
            cornerRadius: 43,
            scale: scale,
            contentType: .oneTimeCode,
            keyboardType: .numberPad,
            submitLabel: .go,
            onSubmit: {
                handleSubmit()
            },
            focusedField: $focusedField,
            focusEquals: .verificationCode
        )
    }

    private func signInButton(scale: CGFloat) -> some View {
        AuthPrimaryActionButton(
            title: buttonTitle,
            scale: scale,
            isEnabled: canSubmit,
            isLoading: isSubmitting,
            loadingTitle: submittingTitle
        ) {
            handleSubmit()
        }
    }
    
    private var buttonTitle: String {
        if mode == .signUp && isAwaitingSignUpVerification {
            return "Verify Email Code"
        }
        return mode == .signUp ? "Sign Up" : "Sign In"
    }
    
    private var submittingTitle: String {
        if mode == .login {
            return "Signing In..."
        }
        if isAwaitingSignUpVerification {
            return "Verifying..."
        }
        return "Creating Account..."
    }
    
    private var isAwaitingSignUpVerification: Bool {
        mode == .signUp && pendingVerificationEmail != nil
    }

    private var canSubmit: Bool {
        switch mode {
        case .login:
            return AuthValidator.canSubmitLogin(email: email, password: password)
        case .signUp:
            if isAwaitingSignUpVerification {
                return AuthValidator.canSubmitSignUpVerification(email: email, verificationCode: verificationCode)
            }
            return AuthValidator.canSubmitSignUp(email: email, password: password, confirmPassword: confirmPassword)
        }
    }

    private func handleSubmit() {
        if isSubmitting {
            return
        }
        
        let errorMessage: String?
        switch mode {
        case .login:
            errorMessage = AuthValidator.loginError(email: email, password: password)
        case .signUp:
            if isAwaitingSignUpVerification {
                errorMessage = AuthValidator.signUpVerificationError(email: email, verificationCode: verificationCode)
            } else {
                errorMessage = AuthValidator.signUpError(email: email, password: password, confirmPassword: confirmPassword)
            }
        }

        if let errorMessage {
            AuthToast.show(errorMessage, showToast: $showToast, toastMessage: $toastMessage)
            return
        }
        
        isSubmitting = true
        signUpFeedbackMessage = nil
        let email = self.email.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = self.password
        
        Task {
            defer {
                Task { @MainActor in
                    isSubmitting = false
                }
            }
            
            do {
                let client = SupabaseAuthClient(
                    supabaseURL: AppConfig.supabaseURL,
                    anonKey: AppConfig.supabaseAnonKey
                )
                
                let response: SupabaseAuthClient.AuthResponse
                switch mode {
                case .login:
                    response = try await client.signInWithPassword(email: email, password: password)
                case .signUp:
                    if let pendingEmail = pendingVerificationEmail {
                        response = try await client.verifySignUp(
                            email: pendingEmail,
                            token: verificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    } else {
                        response = try await client.signUp(email: email, password: password)
                    }
                }
                
                let userId = response.user?.id ?? UUID().uuidString
                guard let accessToken = response.resolvedAccessToken else {
                    if mode == .signUp {
                        await MainActor.run {
                            pendingVerificationEmail = email
                            verificationCode = ""
                            signUpFeedbackMessage = "Registration successful. Enter the verification code sent to your email."
                            AuthToast.show("Registration successful. Enter the verification code sent to your email.", showToast: $showToast, toastMessage: $toastMessage)
                            focusedField = .verificationCode
                        }
                        return
                    }
                    throw SupabaseAuthClient.ClientError.missingSession
                }
                
                await MainActor.run {
                    pendingVerificationEmail = nil
                    verificationCode = ""
                    AuthManager.shared.saveSession(
                        accessToken: accessToken,
                        refreshToken: response.resolvedRefreshToken,
                        userId: userId,
                        email: response.user?.email ?? email,
                        expiresIn: response.resolvedExpiresIn
                    )
                    onLoginSuccess()
                }
            } catch {
                await MainActor.run {
                    let message: String
                    if mode == .signUp {
                        if isAwaitingSignUpVerification {
                            message = "We couldn’t verify your code. Please try again."
                        } else {
                            message = "We couldn’t create your account. Please try again."
                        }
                        signUpFeedbackMessage = message
                    } else {
                        message = "Sign-in failed. Please check your credentials and try again."
                    }
                    AuthToast.show(message, showToast: $showToast, toastMessage: $toastMessage)
                }
            }
        }
    }

}

struct AuthValidator {
    private static let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"

    static func isEmailValid(_ email: String) -> Bool {
        NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    static func canSubmitLogin(email: String, password: String) -> Bool {
        isEmailValid(email) && !password.isEmpty
    }

    static func canSubmitSignUp(email: String, password: String, confirmPassword: String) -> Bool {
        isEmailValid(email) && !password.isEmpty && password == confirmPassword
    }
    
    static func canSubmitSignUpVerification(email: String, verificationCode: String) -> Bool {
        isEmailValid(email) && !verificationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func canSubmitReset(email: String, password: String, confirmPassword: String) -> Bool {
        canSubmitSignUp(email: email, password: password, confirmPassword: confirmPassword)
    }

    static func loginError(email: String, password: String) -> String? {
        if !isEmailValid(email) {
            return "Please enter a valid email address."
        }

        if password.isEmpty {
            return "Please enter your password"
        }

        return nil
    }

    static func signUpError(email: String, password: String, confirmPassword: String) -> String? {
        if !isEmailValid(email) {
            return "Please enter a valid email address."
        }

        if password.isEmpty {
            return "Please enter your password"
        }

        if confirmPassword.isEmpty {
            return "Please confirm your password"
        }

        if password != confirmPassword {
            return "Passwords do not match"
        }

        return nil
    }

    static func resetPasswordError(email: String, password: String, confirmPassword: String) -> String? {
        signUpError(email: email, password: password, confirmPassword: confirmPassword)
    }
    
    static func signUpVerificationError(email: String, verificationCode: String) -> String? {
        if !isEmailValid(email) {
            return "Please enter a valid email address."
        }
        
        if verificationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Please enter the verification code"
        }
        
        return nil
    }
}

struct AuthToast {
    static func show(_ message: String, showToast: Binding<Bool>, toastMessage: Binding<String>) {
        toastMessage.wrappedValue = message
        withAnimation {
            showToast.wrappedValue = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast.wrappedValue = false
            }
        }
    }
}

struct AuthToastOverlay: View {
    let isVisible: Bool
    let message: String
    let topPadding: CGFloat

    var body: some View {
        Group {
            if isVisible {
                VStack {
                    AuthToastView(message: message)
                        .padding(.top, topPadding)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
                .allowsHitTesting(false)
            }
        }
    }
}

struct AuthToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 14))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .frame(maxWidth: 248)
            .background(Color.black.opacity(0.8))
            .cornerRadius(20)
    }
}

struct AuthInputField<FocusField: Hashable>: View {
    let text: Binding<String>
    let placeholder: String
    let isSecure: Bool
    let cornerRadius: CGFloat
    let scale: CGFloat
    let contentType: UITextContentType?
    let keyboardType: UIKeyboardType
    let submitLabel: SubmitLabel
    let onSubmit: () -> Void
    let focusedField: FocusState<FocusField?>.Binding
    let focusEquals: FocusField

    var body: some View {
        Group {
            if isSecure {
                SecureField("", text: text, prompt: promptView)
            } else {
                TextField("", text: text, prompt: promptView)
            }
        }
        .font(.system(size: 14 * scale, weight: .medium)) // Replaced Poppins-Regular with System Font
        .foregroundColor(.white)
        .textInputAutocapitalization(.never)
        .textContentType(contentType)
        .keyboardType(keyboardType)
        .autocorrectionDisabled()
        .submitLabel(submitLabel)
        .onSubmit(onSubmit)
        .padding(.vertical, 20 * scale)
        .padding(.horizontal, 16 * scale)
        .frame(width: 332 * scale)
        .background(Color.white.opacity(0.2))
        .cornerRadius(cornerRadius * scale)
        .focused(focusedField, equals: focusEquals)
    }

    private var promptView: Text {
        Text(placeholder)
            .kerning(0.7 * scale)
            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
    }
}

struct EmailSignUpBackground: View {
    let scale: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(red: 0.0627, green: 0.0627, blue: 0.1176)

            Ellipse()
                .fill(Color(red: 1.0, green: 0.7686, blue: 0.7961))
                .frame(width: 610 * scale, height: 416 * scale)
                .blur(radius: 200 * scale)
                .position(
                    x: (-128 + 610 / 2) * scale,
                    y: (-229 + 416 / 2) * scale
                )

            Ellipse()
                .fill(Color(red: 1.0, green: 0.2980, blue: 0.3843))
                .frame(width: 235 * scale, height: 254 * scale)
                .blur(radius: 90 * scale)
                .position(
                    x: (86 + 235 / 2) * scale,
                    y: (-127 + 254 / 2) * scale
                )

            Image("SignInDecoration")
                .resizable()
                .interpolation(.low)
                .scaledToFit()
                .frame(width: 152 * scale, height: 152 * scale)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 100 * scale)
                .padding(.trailing, 28 * scale)

            Ellipse()
                .fill(Color(red: 0.5059, green: 0.7843, blue: 0.8627))
                .frame(width: 263 * scale, height: 230 * scale)
                .blur(radius: 76 * scale)
                .position(
                    x: (203 + 263 / 2) * scale,
                    y: (513 + 230 / 2) * scale
                )

            Ellipse()
                .fill(Color(red: 0.9686, green: 0.6980, blue: 0.3412))
                .frame(width: 107 * scale, height: 156 * scale)
                .blur(radius: 76 * scale)
                .position(
                    x: (321 + 107 / 2) * scale,
                    y: (416 + 156 / 2) * scale
                )
        }
        .drawingGroup()
    }
}

struct EmailSignUpView_Previews: PreviewProvider {
    static var previews: some View {
        EmailSignUpView(mode: .signUp, onLoginSuccess: {}, onForgotPassword: {}, onBack: {})
    }
}
