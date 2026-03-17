
//
//  ContentView.swift
//  xcodegame
//
//  Created by Zhan Si on 2026/1/6.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var selectedTab: NavTab = .home
    @ObservedObject private var authManager = AuthManager.shared
    @State private var authPath: [AuthRoute] = []
    @State private var isLoginAgreementChecked = false
    @State private var didRestoreSession = false
    @State private var isTabBarHidden = false
    @State private var showAddOverlay = false
    @State private var showMakeupShare = false
    @State private var showReleaseVideo = false
    @State private var showBanUserPopup = false
    @State private var showReportPopup = false
    @State private var pendingBanUser: BanUserTarget?
    @State private var lastPrefetchedUserId: String?
    @StateObject private var blockedUsersStore = BlockedUsersStore()
    @StateObject private var chatListStore = ChatListStore()
    @StateObject private var profileStatsStore = ProfileStatsStore()
    
    var body: some View {
        Group {
            if authManager.isLoggedIn {
                mainContent
                    .overlay {
                        if showAddOverlay {
                            AddView(onClose: {
                                withAnimation {
                                    showAddOverlay = false
                                }
                            }, onMakeupShare: {
                                withAnimation {
                                    showAddOverlay = false
                                }
                                showMakeupShare = true
                            }, onReleaseVideo: {
                                withAnimation {
                                    showAddOverlay = false
                                }
                                showReleaseVideo = true
                            })
                            .transition(.opacity)
                            .zIndex(100)
                        }
                    }
                    .fullScreenCover(isPresented: $showMakeupShare) {
                        MakeupShareView()
                    }
                    .fullScreenCover(isPresented: $showReleaseVideo) {
                        ReleaseVideoView()
                    }
            } else if authManager.isLoading {
                LaunchScreenView()
            } else {
                NavigationStack(path: $authPath) {
                    LoginSelectionView(isAgreementChecked: $isLoginAgreementChecked, onLoginSuccess: handleLoginSuccess, onShowEmailLogin: showEmailLogin, onShowEmailSignUp: showEmailSignUp, onShowEULA: showEULA)
                        .navigationDestination(for: AuthRoute.self) { route in
                            switch route {
                            case .emailLogin:
                                EmailSignUpView(mode: .login, onLoginSuccess: handleLoginSuccess, onForgotPassword: showForgotPasswordFromLogin, onBack: handleBack)
                                    .navigationBarBackButtonHidden(true)
                            case .emailSignUp:
                                EmailSignUpView(mode: .signUp, onLoginSuccess: handleLoginSuccess, onForgotPassword: showForgotPasswordFromSignUp, onBack: handleBack)
                                    .navigationBarBackButtonHidden(true)
                            case .forgotPassword:
                                ForgotPasswordView(onComplete: handlePasswordResetComplete, onBack: handleBack)
                                    .navigationBarBackButtonHidden(true)
                            case .eula:
                                EULAView(
                                    onBack: handleBack,
                                    onSure: {
                                        isLoginAgreementChecked = true
                                        handleBack()
                                    }
                                )
                                .navigationBarBackButtonHidden(true)
                            case .userAgreement:
                                UserAgreementView()
                                    .navigationBarBackButtonHidden(true)
                            case .privacyPolicy:
                                PrivacyPolicyView()
                                    .navigationBarBackButtonHidden(true)
                            }
                        }
                        .navigationBarHidden(true)
                }
            }
        }
        .onAppear {
            if !didRestoreSession {
                didRestoreSession = true
                authManager.restoreSession()
            }
        }
    }
    
    var mainContent: some View {
        GeometryReader { proxy in
            AppScreen {
                ZStack(alignment: .bottom) {
                    ZStack {
                        CachedTab(tab: .home, isSelected: selectedTab == .home) {
                            HomeView()
                        }

                        CachedTab(tab: .shorts, isSelected: selectedTab == .shorts) {
                            ShortsView(isTabSelected: selectedTab == .shorts)
                        }

                        CachedTab(tab: .messages, isSelected: selectedTab == .messages) {
                            MessageView()
                        }

                        CachedTab(tab: .profile, isSelected: selectedTab == .profile) {
                            ProfileView(onLogout: handleLogout)
                        }
                    }

                    if !isTabBarHidden && !showAddOverlay {
                        MainTabView(selectedTab: $selectedTab, onAddTap: {
                            withAnimation {
                                showAddOverlay = true
                            }
                        })
                        .padding(.bottom, 0)
                        .ignoresSafeArea(.container, edges: .bottom)
                        .transition(.opacity)
                    }
                }
            }
        }
        .environment(\.tabBarHiddenBinding, $isTabBarHidden)
        .environment(\.selectedNavTab, selectedTab)
        .environment(\.selectedNavTabBinding, $selectedTab)
        .environment(\.blockedUsersStore, blockedUsersStore)
        .environmentObject(blockedUsersStore)
        .environmentObject(chatListStore)
        .environmentObject(profileStatsStore)
        .appPopup(isPresented: $showBanUserPopup) {
            BanUserPopup(
                onReport: {
                    showBanUserPopup = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showReportPopup = true
                    }
                },
                onBlock: {
                    if let pendingBanUser {
                        blockedUsersStore.block(pendingBanUser)
                    }
                    showBanUserPopup = false
                },
                onCancel: {
                    showBanUserPopup = false
                }
            )
        }
        .appPopup(isPresented: $showReportPopup) {
            ReportPopup(
                onSubmit: { _ in
                    showReportPopup = false
                },
                onCancel: {
                    showReportPopup = false
                }
            )
        }
        .environment(\.banUserAction, { target in
            pendingBanUser = target
            withAnimation {
                showBanUserPopup = true
            }
        })
        .onReceive(authManager.$isLoggedIn.removeDuplicates()) { isLoggedIn in
            if isLoggedIn {
                handleUserLoggedIn()
            }
        }
    }

    private struct CachedTab<Content: View>: View {
        let tab: NavTab
        let isSelected: Bool
        let content: () -> Content
        @State private var didLoad = false

        var body: some View {
            Group {
                if isSelected || didLoad {
                    content()
                        .background(TabBarVisibilitySync(isEnabled: isSelected))
                        .onAppear { didLoad = true }
                } else {
                    Color.clear
                }
            }
            .opacity(isSelected ? 1 : 0)
            .allowsHitTesting(isSelected)
            .accessibilityHidden(!isSelected)
        }
    }

    private func handleLoginSuccess() {
        handleUserLoggedIn()
        authPath.removeAll()
    }
    
    private func handleUserLoggedIn() {
        guard let userId = authManager.currentUserId else { return }
        guard lastPrefetchedUserId != userId else { return }
        lastPrefetchedUserId = userId
        
        blockedUsersStore.setCurrentUserId(userId)
        profileStatsStore.setCurrentUserId(userId)
        
        Task {
            await blockedUsersStore.loadFromServer(userId: userId)
            await profileStatsStore.loadFromServer(userId: userId)
        }
    }

    private func handleLogout() {
        authManager.signOut()
        selectedTab = .home
        isTabBarHidden = false
        showAddOverlay = false
        showMakeupShare = false
        showReleaseVideo = false
        showBanUserPopup = false
        showReportPopup = false
        pendingBanUser = nil
        authPath.removeAll()
        lastPrefetchedUserId = nil
        
        blockedUsersStore.setCurrentUserId(nil)
        profileStatsStore.setCurrentUserId(nil)
        chatListStore.items = []
    }

    private func showEmailLogin() {
        authPath.append(.emailLogin)
    }

    private func showEmailSignUp() {
        authPath.append(.emailSignUp)
    }

    private func showForgotPasswordFromLogin() {
        authPath.append(.forgotPassword(source: .login))
    }

    private func showForgotPasswordFromSignUp() {
        authPath.append(.forgotPassword(source: .signUp))
    }
    
    private func showEULA() {
        authPath.append(.eula)
    }

    private func handlePasswordResetComplete() {
        authPath = [.emailLogin]
    }

    private func handleBack() {
        if !authPath.isEmpty {
            authPath.removeLast()
        }
    }
}

enum ForgotPasswordSource: Hashable {
    case login
    case signUp
}

enum AuthRoute: Hashable {
    case emailLogin
    case emailSignUp
    case forgotPassword(source: ForgotPasswordSource)
    case eula
    case userAgreement
    case privacyPolicy
}

enum NavTab: String, CaseIterable {
    case home
    case shorts
    case add
    case messages
    case profile
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .shorts: return "Shorts"
        case .add: return "Create"
        case .messages: return "Messages"
        case .profile: return "Profile"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
