import SwiftUI

struct UserAgreementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var doc: AgreementDocument?
    @State private var isLoading = true
    @State private var errorText: String?

    var body: some View {
        GeometryReader { proxy in
            let topInset = proxy.safeAreaInsets.top
            let scale = min(proxy.size.width / 375, proxy.size.height / 812)

            AppScreen {
                ZStack(alignment: .top) {
                    AppScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16 * scale) {
                            Text(doc?.title ?? "User Agreement")
                                .font(.custom("Notable-Regular", size: 20 * scale))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }

                            if let errorText {
                                Text(errorText)
                                    .font(.system(size: 12 * scale))
                                    .foregroundStyle(.white.opacity(0.7))
                            }

                            Text(doc?.content ?? "")
                                .font(.system(size: 14 * scale))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineSpacing(4)
                                .multilineTextAlignment(.leading)

                            if let termsURL = AppConfig.termsOfUseURL {
                                Button("Open in Browser") {
                                    openURL(termsURL)
                                }
                                .font(.system(size: 14 * scale, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44 * scale)
                                .background(Color.white.opacity(0.14))
                                .clipShape(.rect(cornerRadius: 22 * scale, style: .continuous))
                                .accessibilityIdentifier("user_agreement_open_in_browser")
                            }
                        }
                        .padding(.top, topInset + 60)
                        .padding(.horizontal, 16 * scale)
                        .padding(.bottom, 24)
                    }

                    HStack(spacing: 12) {
                        AppBackButton {
                            dismiss()
                        }

                        Text(doc?.title ?? "User Agreement")
                            .font(.custom("Notable-Regular", size: 20 * scale))
                            .foregroundStyle(.white)

                        Spacer()
                    }
                    .padding(.leading, 16)
                    .padding(.top, 10)
                    .padding(.trailing, 16)
                }
            }
            .background(TabBarVisibilitySync())
            .navigationBarHidden(true)
        }
        .task {
            await load()
        }
    }

    @MainActor
    private func load() async {
        do {
            doc = try await AgreementsService.shared.fetchRemote(kind: .userAgreement)
            errorText = nil
        } catch {
            errorText = error.localizedDescription
        }

        isLoading = false
    }
}

struct UserAgreementView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                UserAgreementView()
            }
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var doc: AgreementDocument?
    @State private var isLoading = true
    @State private var errorText: String?

    var body: some View {
        GeometryReader { proxy in
            let topInset = proxy.safeAreaInsets.top
            let scale = min(proxy.size.width / 375, proxy.size.height / 812)

            AppScreen {
                ZStack(alignment: .top) {
                    AppScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16 * scale) {
                            Text(doc?.title ?? "Privacy Policy")
                                .font(.custom("Notable-Regular", size: 20 * scale))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }

                            if let errorText {
                                Text(errorText)
                                    .font(.system(size: 12 * scale))
                                    .foregroundStyle(.white.opacity(0.7))
                            }

                            Text(doc?.content ?? "")
                                .font(.system(size: 14 * scale))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineSpacing(4)
                                .multilineTextAlignment(.leading)

                            if let privacyURL = AppConfig.privacyPolicyURL {
                                Button("Open in Browser") {
                                    openURL(privacyURL)
                                }
                                .font(.system(size: 14 * scale, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44 * scale)
                                .background(Color.white.opacity(0.14))
                                .clipShape(.rect(cornerRadius: 22 * scale, style: .continuous))
                                .accessibilityIdentifier("privacy_policy_open_in_browser")
                            }
                        }
                        .padding(.top, topInset + 60)
                        .padding(.horizontal, 16 * scale)
                        .padding(.bottom, 24)
                    }

                    HStack(spacing: 12) {
                        AppBackButton {
                            dismiss()
                        }

                        Text(doc?.title ?? "Privacy Policy")
                            .font(.custom("Notable-Regular", size: 20 * scale))
                            .foregroundStyle(.white)

                        Spacer()
                    }
                    .padding(.leading, 16)
                    .padding(.top, 10)
                    .padding(.trailing, 16)
                }
            }
            .background(TabBarVisibilitySync())
            .navigationBarHidden(true)
        }
        .task {
            await load()
        }
    }

    @MainActor
    private func load() async {
        do {
            doc = try await AgreementsService.shared.fetchRemote(kind: .privacyPolicy)
            errorText = nil
        } catch {
            errorText = error.localizedDescription
        }

        isLoading = false
    }
}

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                PrivacyPolicyView()
            }
        }
    }
}
