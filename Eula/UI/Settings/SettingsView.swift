import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarHiddenBinding) private var tabBarHiddenBinding
    let onLogout: () -> Void
    @State private var showBlockedList = false
    @State private var showPrivacyPolicyPage = false
    @State private var showUserAgreementPage = false
    @State private var showDeleteAccount = false

    init(onLogout: @escaping () -> Void = { }) {
        self.onLogout = onLogout
    }

    var body: some View {
        GeometryReader { proxy in
            let topInset = proxy.safeAreaInsets.top
            let scale = min(proxy.size.width / 375, proxy.size.height / 812)
            
            AppScreen {
                ZStack(alignment: .top) {
                    // Content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16 * scale) {
                            SettingsRow(icon: "settings_privacy_icon", title: "Privacy Policy", scale: scale) {
                                showPrivacyPolicyPage = true
                            }
                            SettingsRow(icon: "settings_blocked_icon", title: "Blocked List", scale: scale) {
                                showBlockedList = true
                            }
                            SettingsRow(icon: "settings_agreement_icon", title: "User Agreement", scale: scale) {
                                showUserAgreementPage = true
                            }
                            SettingsRow(icon: "settings_delete_icon", title: "Delete Account", scale: scale) {
                                showDeleteAccount = true
                            }
                            SettingsRow(icon: "settings_logout_icon", title: "Log out", scale: scale) {
                                onLogout()
                                dismiss()
                            }
                        }
                        .padding(.top, topInset + 60) // Top bar height + spacing
                        .padding(.horizontal, 16 * scale)
                    }

                    // Top Bar
                    HStack(spacing: 12) {
                        AppBackButton {
                            dismiss()
                        }

                        Text("Set up")
                            .font(.custom("Notable-Regular", size: 20 * scale))
                            .foregroundStyle(.white)

                        Spacer()
                    }
                    .padding(.leading, 16)
                    .padding(.top, 10)
                    .padding(.trailing, 16)
                }
            }
            .appPopup(isPresented: $showBlockedList) {
                BlockedListPopup(isPresented: $showBlockedList)
            }
            .appPopup(isPresented: $showDeleteAccount) {
                DeleteAccountPopup(
                    onSure: {
                        showDeleteAccount = false
                        onLogout()
                        ToastManager.shared.show("Account access has been removed on this device")
                        dismiss()
                    },
                    onCancel: {
                        showDeleteAccount = false
                    }
                )
            }
            .navigationDestination(isPresented: $showUserAgreementPage) {
                UserAgreementView()
            }
            .navigationDestination(isPresented: $showPrivacyPolicyPage) {
                PrivacyPolicyView()
            }
            .background(TabBarVisibilitySync())
            .navigationBarHidden(true)
            .toast()
            .onAppear {
                tabBarHiddenBinding?.wrappedValue = true
            }
            .onDisappear {
                if !showUserAgreementPage && !showPrivacyPolicyPage {
                    tabBarHiddenBinding?.wrappedValue = false
                }
            }
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    let scale: CGFloat
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            Image(icon)
                .resizable()
                .frame(width: 18 * scale, height: 18 * scale)
                .padding(.leading, 10 * scale)
            
            Text(title)
                .font(.system(size: 16 * scale, weight: .regular))
                .foregroundStyle(.white)
                .padding(.leading, 4 * scale)
            
            Spacer()
            
            Image("settings_chevron_right")
                .resizable()
                .frame(width: 24 * scale, height: 24 * scale)
                .padding(.trailing, 10 * scale)
        }
        .frame(height: 54 * scale)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20 * scale, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20 * scale, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .onTapGesture {
            impactFeedback()
            action?()
        }
    }
}

private struct BlockedListPopup: View {
    @Binding var isPresented: Bool

    @EnvironmentObject private var blockedUsersStore: BlockedUsersStore
    
    var body: some View {
        AppPopupScaffold(height: 452) {
            VStack(spacing: 0) {
                Text("Blocked List")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.top, 40)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        let users = blockedUsersStore.users

                        if users.isEmpty {
                            Text("No blocked users")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(.black.opacity(0.6))
                                .padding(.top, 40)
                        } else {
                            ForEach(users) { user in
                                HStack {
                                    Image(user.avatarName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())

                                    Text(user.name)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundStyle(.black)

                                    Spacer()

                                    Button("Unblock") {
                                        impactFeedback()
                                        blockedUsersStore.unblock(user.id)
                                    }
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(hexString: "81C8DC"))
                                    .clipShape(Capsule())
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                .frame(height: 280)
                
                Spacer()
                
                AppPopupActionButton(
                    title: "Close",
                    color: Color(hexString: "ACB1D7"),
                    width: 128,
                    height: 48,
                    fontSize: 14
                ) {
                    isPresented = false
                }
                .padding(.bottom, 40)
            }
        }
    }
}

private func impactFeedback() {
    #if canImport(UIKit)
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    #endif
}
