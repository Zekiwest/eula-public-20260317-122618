import SwiftUI

struct UserAgreementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var doc = AgreementDocument(
        title: AgreementKind.userAgreement.defaultTitle,
        content: AgreementKind.userAgreement.defaultContent,
        updatedAt: nil
    )
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
                            Text(doc.title)
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

                            Text(doc.content)
                                .font(.system(size: 14 * scale))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineSpacing(4)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.top, topInset + 60)
                        .padding(.horizontal, 16 * scale)
                        .padding(.bottom, 24)
                    }

                    HStack(spacing: 12) {
                        AppBackButton {
                            dismiss()
                        }

                        Text(doc.title)
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
        if let cached = AgreementsService.shared.loadCached(kind: .userAgreement) {
            doc = cached
        }

        do {
            doc = try await AgreementsService.shared.fetchRemote(kind: .userAgreement)
            errorText = nil
        } catch {
            if doc.content.isEmpty {
                doc = AgreementDocument(
                    title: AgreementKind.userAgreement.defaultTitle,
                    content: AgreementKind.userAgreement.defaultContent,
                    updatedAt: nil
                )
            }
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
    @State private var doc = AgreementDocument(
        title: AgreementKind.privacyPolicy.defaultTitle,
        content: AgreementKind.privacyPolicy.defaultContent,
        updatedAt: nil
    )
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
                            Text(doc.title)
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

                            Text(doc.content)
                                .font(.system(size: 14 * scale))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineSpacing(4)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.top, topInset + 60)
                        .padding(.horizontal, 16 * scale)
                        .padding(.bottom, 24)
                    }

                    HStack(spacing: 12) {
                        AppBackButton {
                            dismiss()
                        }

                        Text(doc.title)
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
        if let cached = AgreementsService.shared.loadCached(kind: .privacyPolicy) {
            doc = cached
        }

        do {
            doc = try await AgreementsService.shared.fetchRemote(kind: .privacyPolicy)
            errorText = nil
        } catch {
            if doc.content.isEmpty {
                doc = AgreementDocument(
                    title: AgreementKind.privacyPolicy.defaultTitle,
                    content: AgreementKind.privacyPolicy.defaultContent,
                    updatedAt: nil
                )
            }
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
