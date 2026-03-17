import SwiftUI

struct ForgotPasswordView: View {
    enum FocusField {
        case email
        case password
        case confirmPassword
    }

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showToast = false
    @State private var toastMessage = ""
    @FocusState private var focusedField: FocusField?

    let onComplete: () -> Void
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
        .ignoresSafeArea()
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
        AuthFormSection(title: "Forgot Password", scale: scale) {
                VStack(alignment: .leading, spacing: 16 * scale) {
                    emailField(scale: scale)
                    passwordField(scale: scale)
                    confirmPasswordField(scale: scale)
                }

                saveButton(scale: scale)
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
            submitLabel: .next,
            onSubmit: {
                focusedField = .confirmPassword
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

    private func saveButton(scale: CGFloat) -> some View {
        AuthPrimaryActionButton(
            title: "Reset Password",
            scale: scale,
            isEnabled: canSubmit
        ) {
            handleSubmit()
        }
    }

    private var canSubmit: Bool {
        AuthValidator.canSubmitReset(email: email, password: password, confirmPassword: confirmPassword)
    }

    private func handleSubmit() {
        if let errorMessage = AuthValidator.resetPasswordError(email: email, password: password, confirmPassword: confirmPassword) {
            AuthToast.show(errorMessage, showToast: $showToast, toastMessage: $toastMessage)
            return
        }

        onComplete()
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView(onComplete: {}, onBack: {})
    }
}
