import SwiftUI

struct MessageView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarHiddenBinding) private var tabBarHiddenBinding
    @EnvironmentObject private var chatListStore: ChatListStore
    @EnvironmentObject private var profileStatsStore: ProfileStatsStore
    @State private var selectedChatItem: MessageItem?
    @State private var isNavigatingToChat = false

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let scale = min(proxy.size.width / 375, proxy.size.height / 812)
                
                AppScreen {
                    ZStack(alignment: .top) {
                        if chatListStore.items.isEmpty {
                            MessagesEmptyState(scale: scale)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.top, 10 + (20 * scale) + 24)
                        } else {
                            ScrollView(showsIndicators: false) {
                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 21 * scale), GridItem(.flexible(), spacing: 21 * scale)], spacing: 24 * scale) {
                                    ForEach(chatListStore.items) { item in
                                        Button {
                                            if profileStatsStore.isMutualFollowing(item.userId) {
                                                selectedChatItem = item
                                                isNavigatingToChat = true
                                            } else {
                                                ToastManager.shared.show("需要互相关注才能聊天")
                                            }
                                        } label: {
                                            MessageCard(item: item, scale: scale)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.top, 10 + (20 * scale) + 24)
                                .padding(.horizontal, 16 * scale)
                                .padding(.bottom, 100)
                            }
                        }
                        
                        // Top Bar
                        HStack {
                            Text("Message")
                                .font(.custom("Notable-Regular", size: 20 * scale))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.leading, 16)
                        .padding(.top, 10)
                        .padding(.trailing, 16)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $isNavigatingToChat) {
                if let item = selectedChatItem {
                    ChatDetailView(name: item.name, avatarName: item.avatar, personaKey: item.personaKey, userId: item.userId)
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

private struct MessagesEmptyState: View {
    let scale: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 22 * scale, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.16),
                                Color.white.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 180 * scale, height: 130 * scale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22 * scale, style: .continuous)
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
                    .offset(x: -12 * scale, y: 14 * scale)

                RoundedRectangle(cornerRadius: 22 * scale, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hexString: "FF8796").opacity(0.28),
                                Color(hexString: "F7B257").opacity(0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200 * scale, height: 140 * scale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22 * scale, style: .continuous)
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )

                HStack(spacing: 10 * scale) {
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 10 * scale, height: 10 * scale)
                    Circle()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: 10 * scale, height: 10 * scale)
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 10 * scale, height: 10 * scale)
                }
                .offset(y: 8 * scale)
            }

            VStack(spacing: 8 * scale) {
                Text("No chats yet")
                    .font(.system(size: 18 * scale, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Start a conversation from someone's profile.")
                    .font(.system(size: 13 * scale, weight: .regular))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 260 * scale)
            }
            .padding(.top, 18 * scale)

            Spacer()
        }
        .padding(.horizontal, 24 * scale)
    }
}

struct MessageItem: Identifiable {
    let id: Int
    let name: String
    let message: String
    let avatar: String
    let unreadCount: Int
    let personaKey: String
    let userId: String
}

struct MessageCard: View {
    let item: MessageItem
    let scale: CGFloat
    
    // Figma Dimensions (Base)
    // Card Width: 161
    // Card Height: 126
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background Rectangle
            // y: 39, width: 161, height: 87
            RoundedRectangle(cornerRadius: 12 * scale)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0), location: 0),
                            .init(color: .white.opacity(0.7), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 87 * scale)
                .padding(.top, 39 * scale)
            
            // Avatar
            // x: 0, y: 0, width: 64, height: 64
            ZStack {
                Image(item.avatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64 * scale, height: 64 * scale)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 135/255, blue: 150/255), // #FF8796
                                        Color(red: 247/255, green: 178/255, blue: 87/255) // #F7B257
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1 * scale
                            )
                    )
                
                // Badge
                // relative to Avatar group (x: 47, y: 0)
                // In Figma, Badge is inside Group 58, at x=47. Avatar is at x=0.
                if item.unreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 17 * scale, height: 17 * scale)
                        
                        Text("\(item.unreadCount)")
                            .font(.system(size: 10 * scale, weight: .medium)) // Poppins 500 -> System Medium
                            .foregroundStyle(.red)
                    }
                    .offset(x: 23.5 * scale, y: -23.5 * scale) // Center relative to avatar center
                }
            }
            // Position avatar
            // In Figma: Avatar Group is at 0,0.
            
            // Name
            // x: 64, y: 38
            Text(item.name)
                .font(.custom("Notable-Regular", size: 20 * scale))
                .foregroundStyle(.white)
                .padding(.leading, 64 * scale)
                .padding(.top, 38 * scale)
            
            // Message
            // x: 8, y: 80
            Text(item.message)
                .font(.system(size: 12 * scale, weight: .medium)) // Poppins 500 -> System Medium
                .foregroundStyle(.white)
                .lineLimit(2)
                .padding(.leading, 8 * scale)
                .padding(.top, 80 * scale)
                .padding(.trailing, 8 * scale) // Add some trailing padding
        }
        .frame(height: 126 * scale)
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    MessageView()
        .environmentObject(ChatListStore())
        .environmentObject(ProfileStatsStore())
}
    }
}
