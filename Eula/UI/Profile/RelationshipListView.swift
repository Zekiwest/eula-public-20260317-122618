import SwiftUI

struct RelationshipListView: View {
    enum Tab {
        case following
        case fans
    }
    
    @State private var selectedTab: Tab
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarHiddenBinding) private var tabBarHiddenBinding
    @EnvironmentObject private var profileStatsStore: ProfileStatsStore
    
    init(initialTab: Tab = .following) {
        _selectedTab = State(initialValue: initialTab)
    }
    
    var body: some View {
        AppScreen {
            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        AppBackButton {
                            dismiss()
                        }
                        
                        Spacer()
                        
                        Color.clear
                            .frame(width: 40, height: 40)
                    }
                    
                    HStack(spacing: 35) {
                        Button {
                            selectedTab = .following
                        } label: {
                            Text("Following")
                                .font(.custom("Notable-Regular", size: 20))
                                .foregroundStyle(selectedTab == .following ? .white : .white.opacity(0.5))
                        }
                        
                        Button {
                            selectedTab = .fans
                        } label: {
                            Text("Fans")
                                .font(.custom("Notable-Regular", size: 20))
                                .foregroundStyle(selectedTab == .fans ? .white : .white.opacity(0.5))
                        }
                    }
                }
                .padding(.top, 10)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        let users = selectedTab == .following ? makeFollowingUsers() : makeFansUsers()
                        
                        if users.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(users) { user in
                                RelationshipUserRow(user: user, onToggleFollow: {
                                    toggleFollow(user)
                                })
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(TabBarVisibilitySync())
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                tabBarHiddenBinding?.wrappedValue = true
            }
        }
        .onDisappear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                tabBarHiddenBinding?.wrappedValue = false
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: selectedTab == .following ? "person.badge.plus" : "person.2")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.5))
            
            Text(selectedTab == .following ? "No following yet" : "No fans yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.top, 60)
    }
    
    private func makeFollowingUsers() -> [RelationshipUser] {
        profileStatsStore.followingUsersList
    }
    
    private func makeFansUsers() -> [RelationshipUser] {
        profileStatsStore.fansUsersList
    }
    
    private func toggleFollow(_ user: RelationshipUser) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            profileStatsStore.toggleFollow(user: user.user.toBanUserTarget())
        }
    }
}

struct RelationshipUserRow: View {
    let user: RelationshipUser
    let onToggleFollow: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 12) {
                UserAvatarView(
                    avatarName: user.user.avatarName,
                    avatarUrl: nil,
                    size: 44,
                    showBorder: false
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(hexString: "FF8796"), Color(hexString: "F7B257")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                
                Text(user.user.name)
                    .font(.custom("Notable-Regular", size: 20))
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            Button {
                onToggleFollow()
            } label: {
                Text(user.status)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(user.status == "Follow" ? .white : Color(hexString: "FF8796"))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(user.status == "Follow" ? Color(hexString: "FF8796") : Color.white)
                    .cornerRadius(20)
            }
            .buttonStyle(PressScaleButtonStyle(scale: 0.95))
        }
        .padding(10)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }
}

struct RelationshipUser: Identifiable {
    let id: String
    let user: User
    let status: String
}

struct RelationshipListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    RelationshipListView()
}
    }
}
