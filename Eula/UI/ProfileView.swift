import SwiftUI
import UIKit

private enum ProfileScrollID {
    static let myTop = "my_profile_scroll_top"
    static let otherTop = "other_profile_scroll_top"
}

struct ProfileView: View {
    @Environment(\.tabBarHiddenBinding) private var tabBarHiddenBinding
    let onLogout: () -> Void
    @State private var isSettingsPresented = false
    @State private var isCollectsPresented = false
    @State private var isWalletPresented = false
    @State private var isMakeupPresented = false
    @State private var isRelationshipListPresented = false
    @State private var relationshipListInitialTab: RelationshipListView.Tab = .following

    init(onLogout: @escaping () -> Void = { }) {
        self.onLogout = onLogout
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let baseWidth: CGFloat = 375
                let baseHeight: CGFloat = 812
                let scale = min(proxy.size.width / baseWidth, proxy.size.height / baseHeight)
                let topInset = proxy.safeAreaInsets.top
                let width = proxy.size.width
                let maskHeight = width * (324.0 / 375.0) * scale

                AppScreen {
                    ZStack(alignment: .top) {
                        Image("profile_mask_bg")
                            .resizable()
                            .frame(width: width, height: maskHeight)
                            .ignoresSafeArea(edges: .top)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                        ScrollViewReader { scrollProxy in
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: 0) {
                                    Color.clear
                                        .frame(height: 0)
                                        .id(ProfileScrollID.myTop)

                                    MyProfileHeaderView(scale: scale)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    Spacer().frame(height: 24 * scale)

                                    MyProfileStatsView(
                                        scale: scale,
                                        onWalletTap: {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            isWalletPresented = true
                                        },
                                        onFollowingTap: {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            relationshipListInitialTab = .following
                                            isRelationshipListPresented = true
                                        },
                                        onFansTap: {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            relationshipListInitialTab = .fans
                                            isRelationshipListPresented = true
                                        }
                                    )

                                    Spacer().frame(height: 24 * scale)

                                    MyProfileMakeupView(
                                        scale: scale,
                                        onItemTap: {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            isMakeupPresented = true
                                        },
                                        onCollectsTap: {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            isCollectsPresented = true
                                        }
                                    )

                                    Spacer().frame(height: 20 * scale)

                                    VideoCardsModuleView(horizontalPadding: 0)
                                }
                                .padding(.top, topInset + 24)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 40 * scale)
                            }
                            .accessibilityIdentifier("my_profile_view")
                            .onAppear {
                                DispatchQueue.main.async {
                                    scrollProxy.scrollTo(ProfileScrollID.myTop, anchor: .top)
                                }
                            }
                            .onChange(of: isSettingsPresented, perform: { isPresented in
                                guard !isPresented else { return }
                                DispatchQueue.main.async {
                                    scrollProxy.scrollTo(ProfileScrollID.myTop, anchor: .top)
                                }
                            })
                            .onChange(of: isCollectsPresented, perform: { isPresented in
                                guard !isPresented else { return }
                                DispatchQueue.main.async {
                                    scrollProxy.scrollTo(ProfileScrollID.myTop, anchor: .top)
                                }
                            })
                            .onChange(of: isMakeupPresented, perform: { isPresented in
                                guard !isPresented else { return }
                                DispatchQueue.main.async {
                                    scrollProxy.scrollTo(ProfileScrollID.myTop, anchor: .top)
                                }
                            })
                            .onChange(of: isRelationshipListPresented, perform: { isPresented in
                                guard !isPresented else { return }
                                DispatchQueue.main.async {
                                    scrollProxy.scrollTo(ProfileScrollID.myTop, anchor: .top)
                                }
                            })
                        }

                        MyProfileTopBar(topInset: topInset, onSettingsTap: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            isSettingsPresented = true
                        })
                        .ignoresSafeArea(.container, edges: .top)
                    }
                }
                .navigationBarHidden(true)
                .navigationDestination(isPresented: $isSettingsPresented) {
                    SettingsView(onLogout: onLogout)
                }
                .navigationDestination(isPresented: $isCollectsPresented) {
                    CollectsView()
                }
                .navigationDestination(isPresented: $isWalletPresented) {
                    WalletRechargeView()
                }
                .navigationDestination(isPresented: $isMakeupPresented) {
                    MakeupVideoView()
                }
                .navigationDestination(isPresented: $isRelationshipListPresented) {
                    RelationshipListView(initialTab: relationshipListInitialTab)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                tabBarHiddenBinding?.wrappedValue = false
            }
        }
    }
}

struct OtherProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarHiddenBinding) private var tabBarHiddenBinding
    @Environment(\.banUserAction) private var banUserAction
    @Environment(\.selectedNavTabBinding) private var selectedNavTabBinding
    @EnvironmentObject private var chatListStore: ChatListStore
    @EnvironmentObject private var profileStatsStore: ProfileStatsStore

    let user: BanUserTarget
    let photoRowImageName: String
    let onMakeupTap: () -> Void

    @State private var isPushingMakeup = false

    init(user: BanUserTarget, photoRowImageName: String, onMakeupTap: @escaping () -> Void = { }) {
        self.user = user
        self.photoRowImageName = photoRowImageName
        self.onMakeupTap = onMakeupTap
    }

    var body: some View {
        GeometryReader { proxy in
            let baseWidth: CGFloat = 375
            let baseHeight: CGFloat = 812
            let scale = min(proxy.size.width / baseWidth, proxy.size.height / baseHeight)
            let topInset = proxy.safeAreaInsets.top
            let width = proxy.size.width
            let maskHeight = width * (324.0 / 375.0) * scale

            AppScreen {
                ZStack(alignment: .top) {
                    Image("profile_mask_bg")
                        .resizable()
                        .frame(width: width, height: maskHeight)
                        .ignoresSafeArea(edges: .top)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                    ScrollViewReader { scrollProxy in
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                Color.clear
                                    .frame(height: 0)
                                    .id(ProfileScrollID.otherTop)

                                OtherProfileHeaderView(scale: scale, user: user)

                                Spacer().frame(height: 24 * scale)

                                OtherProfileStatsView(
                                    scale: scale,
                                    user: user,
                                    onChatTap: handleChatTap
                                )

                                Spacer().frame(height: 24 * scale)

                                OtherProfileMakeupView(
                                    scale: scale,
                                    photoRowImageName: photoRowImageName,
                                    onItemTap: {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        isPushingMakeup = true
                                        onMakeupTap()
                                    }
                                )

                                Spacer().frame(height: 20 * scale)

                                VideoCardsModuleView(horizontalPadding: 0)
                            }
                            .padding(.top, topInset + 24)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 40 * scale)
                        }
                        .accessibilityIdentifier("personal_homepage_view")
                        .onAppear {
                            DispatchQueue.main.async {
                                scrollProxy.scrollTo(ProfileScrollID.otherTop, anchor: .top)
                            }
                        }
                    }

                    AppTopBar(
                        topInset: topInset,
                        leadingIconName: "EULA_BackIcon",
                        trailingIconName: "more_detail_more",
                        onLeadingTap: { dismiss() },
                        onTrailingTap: { banUserAction?(user) }
                    )
                    .ignoresSafeArea(.container, edges: .top)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                isPushingMakeup = false
                tabBarHiddenBinding?.wrappedValue = true
            }
            .onDisappear {
                guard !isPushingMakeup else { return }
                tabBarHiddenBinding?.wrappedValue = false
            }
        }
    }

    private func handleChatTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if profileStatsStore.isMutualFollowing(user.id) {
            chatListStore.ensureChat(for: user)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedNavTabBinding?.wrappedValue = .messages
            }
            dismiss()
        } else {
            ToastManager.shared.show("Mutual follow is required to chat")
        }
    }
}

@ViewBuilder
func otherProfileViewDestination(
    user: BanUserTarget,
    photoRowImageName: String,
    onMakeupTap: @escaping () -> Void
) -> some View {
    OtherProfileView(user: user, photoRowImageName: photoRowImageName, onMakeupTap: onMakeupTap)
}

private struct MyProfileTopBar: View {
    let topInset: CGFloat
    let onSettingsTap: () -> Void

    var body: some View {
        HStack {
            Color.clear
                .frame(width: 40, height: 40)

            Spacer()

            Button(action: onSettingsTap) {
                Image("my_profile_settings_icon")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("my_profile_settings_button")
            .accessibilityLabel("Settings")
        }
        .padding(.top, topInset + 10)
        .padding(.horizontal, 16)
    }
}

private struct MyProfileHeaderView: View {
    @ObservedObject private var authManager = AuthManager.shared
    let scale: CGFloat

    var body: some View {
        let user = authManager.currentUser
        let displayName = user?.displayName ?? MockProfile.currentUser.name
        let avatarUrl = user?.avatarUrl
        let avatarName = user?.hasCustomAvatar == false ? nil : MockProfile.currentUser.avatarName

        VStack(alignment: .leading, spacing: 10 * scale) {
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color(hexString: "FF8796"), Color(hexString: "F7B257")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .background(
                    Circle().fill(Color.white.opacity(0.1))
                )
                .frame(width: 82 * scale, height: 82 * scale)
                .overlay {
                    UserAvatarView(
                        avatarName: avatarName,
                        avatarUrl: avatarUrl,
                        size: 70 * scale,
                        showBorder: false
                    )
                }

            HStack(spacing: 2 * scale) {
                Text(displayName.uppercased())
                    .font(.custom("Notable-Regular", size: 20 * scale))
                    .foregroundStyle(.white)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image("my_profile_edit_icon")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26 * scale, height: 26 * scale)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressScaleButtonStyle(scale: 0.94, opacity: 0.75))
                .accessibilityIdentifier("my_profile_edit_button")
                .accessibilityLabel("Edit profile")
            }
        }
        .frame(width: 114 * scale, alignment: .leading)
        .padding(.top, 22 * scale)
    }
}

private struct MyProfileStatsView: View {
    @EnvironmentObject private var profileStatsStore: ProfileStatsStore
    let scale: CGFloat
    let onWalletTap: () -> Void
    let onFollowingTap: () -> Void
    let onFansTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 40 * scale) {
                Button(action: onFollowingTap) {
                    VStack(spacing: 6 * scale) {
                        AnimatedStatCountText(
                            value: profileStatsStore.myStats.followingCount,
                            scale: scale
                        )
                        Text("Following")
                            .font(.system(size: 14 * scale, weight: .regular))
                            .foregroundStyle(Color.black.opacity(0.7))
                    }
                }
                .buttonStyle(.plain)

                Button(action: onFansTap) {
                    VStack(spacing: 6 * scale) {
                        AnimatedStatCountText(
                            value: profileStatsStore.myStats.fansCount,
                            scale: scale
                        )
                        Text("Fans")
                            .font(.system(size: 14 * scale, weight: .regular))
                            .foregroundStyle(Color.black.opacity(0.7))
                    }
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button(action: onWalletTap) {
                HStack(spacing: 3 * scale) {
                    Image("my_profile_wallet_icon")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44 * scale, height: 44 * scale)

                    Text("wallet")
                        .font(.system(size: 16 * scale, weight: .medium))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .frame(height: 44 * scale)
                .background(
                    LinearGradient(
                        colors: [Color(hexString: "FF8796"), Color(hexString: "F7B257")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20 * scale, style: .continuous))
            }
            .accessibilityIdentifier("profile_wallet_button")
            .accessibilityLabel("Wallet")
            .buttonStyle(PressScaleButtonStyle(scale: 0.94, opacity: 0.75))
        }
        .padding(.horizontal, 18 * scale)
        .padding(.vertical, 11 * scale)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20 * scale, style: .continuous))
    }
}

private struct MyProfileMakeupView: View {
    let scale: CGFloat
    let onItemTap: () -> Void
    let onCollectsTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16 * scale) {
            HStack {
                Text("MAKEUP")
                    .font(.custom("Notable-Regular", size: 16 * scale))
                    .foregroundStyle(.white)

                Spacer()

                Button(action: onCollectsTap) {
                    Text("Collects >")
                        .font(.system(size: 16 * scale, weight: .regular))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("my_profile_collects_button")
                .accessibilityLabel("Collects")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Image("makeup_row")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 110 * scale)
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        TapGesture().onEnded { onItemTap() }
                    )
            }
        }
    }
}

private struct OtherProfileHeaderView: View {
    @EnvironmentObject private var profileStatsStore: ProfileStatsStore
    let scale: CGFloat
    let user: BanUserTarget

    var body: some View {
        let isFollowing = profileStatsStore.isFollowing(user)
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 10 * scale) {
                Image(user.avatarName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 82 * scale, height: 82 * scale)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )

                Text(user.name)
                    .font(.custom("Notable-Regular", size: 20 * scale))
                    .foregroundStyle(.white)
            }

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    profileStatsStore.toggleFollow(user: user)
                }
            } label: {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.system(size: 16 * scale, weight: .regular))
                    .foregroundStyle(isFollowing ? Color.black.opacity(0.6) : Color(hexString: "FF8796"))
                    .padding(.horizontal, 10 * scale)
                    .frame(height: 30 * scale)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(PressScaleButtonStyle(scale: 0.96, opacity: 0.9))
            .padding(.top, 26 * scale)
        }
    }
}

private struct OtherProfileStatsView: View {
    @EnvironmentObject private var profileStatsStore: ProfileStatsStore
    let scale: CGFloat
    let user: BanUserTarget
    let onChatTap: () -> Void

    var body: some View {
        let stats = profileStatsStore.stats(for: user)
        HStack(spacing: 0) {
            HStack(spacing: 40 * scale) {
                VStack(spacing: 6 * scale) {
                    AnimatedStatCountText(
                        value: stats.followingCount,
                        scale: scale
                    )
                    Text("Following")
                        .font(.system(size: 14 * scale, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.7))
                }

                VStack(spacing: 6 * scale) {
                    AnimatedStatCountText(
                        value: stats.fansCount,
                        scale: scale
                    )
                    Text("Fans")
                        .font(.system(size: 14 * scale, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.7))
                }
            }

            Spacer()

            Button {
                onChatTap()
            } label: {
                HStack(spacing: 3 * scale) {
                    Image("profile_chat_icon")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 42 * scale, height: 42 * scale)
                        .clipShape(Circle())

                    Text("Chat")
                        .font(.system(size: 16 * scale, weight: .medium))
                        .foregroundStyle(.white)
                }
                .padding(.leading, 10)
                .padding(.trailing, 16 * scale)
                .frame(height: 42 * scale)
                .background(
                    LinearGradient(
                        colors: [Color(hexString: "FF8796"), Color(hexString: "F7B257")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
            }
            .accessibilityIdentifier("profile_chat_button")
            .accessibilityLabel("Chat")
            .buttonStyle(PressScaleButtonStyle(scale: 0.94, opacity: 0.75))
        }
        .padding(.horizontal, 18 * scale)
        .padding(.vertical, 11 * scale)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20 * scale, style: .continuous))
    }
}

private struct OtherProfileMakeupView: View {
    let scale: CGFloat
    let photoRowImageName: String
    let onItemTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16 * scale) {
            Text("MAKEUP")
                .font(.custom("Notable-Regular", size: 16 * scale))
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12 * scale) {
                    ForEach(MockContent.galleryImages(primaryImageName: photoRowImageName), id: \.self) { imageName in
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 110 * scale, height: 110 * scale)
                            .clipShape(RoundedRectangle(cornerRadius: 18 * scale, style: .continuous))
                    }
                }
                .contentShape(Rectangle())
                .highPriorityGesture(
                    TapGesture().onEnded { onItemTap() }
                )
            }
        }
    }
}

private struct AnimatedStatCountText: View {
    @EnvironmentObject private var profileStatsStore: ProfileStatsStore

    let value: Int
    let scale: CGFloat

    var body: some View {
        Group {
            if #available(iOS 17.0, *) {
                Text(profileStatsStore.displayCount(value))
                    .contentTransition(.numericText())
            } else {
                Text(profileStatsStore.displayCount(value))
            }
        }
        .font(.custom("Notable-Regular", size: 16 * scale))
        .foregroundStyle(Color.black)
        .monospacedDigit()
        .animation(.easeInOut(duration: 0.25), value: value)
    }
}
