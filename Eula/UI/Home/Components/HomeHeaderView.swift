import SwiftUI

struct HomeHeaderView: View {
    @EnvironmentObject private var blockedUsersStore: BlockedUsersStore

    var body: some View {
        let cards: [NewestCardItem] = MockContent.newestCards

        let visibleCards = cards.filter { card in
            !blockedUsersStore.isBlocked(card.author.id)
        }

        AppScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(visibleCards) { card in
                    NewestCard(
                        imageName: card.imageName,
                        author: card.author,
                        attentionCount: card.attentionCount,
                        title: card.title
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct NewestCard: View {
    let imageName: String
    let author: User
    let attentionCount: String
    let title: String
    private let topBarBlurIntensity: CGFloat = 0.2
    private let followBlurIntensity: CGFloat = 0.35
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 200, height: 300)
                .clipped()
            
            VStack {
                Spacer()
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.0),
                                    .init(color: .black, location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                        .environment(\.colorScheme, .dark)
                    
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0), location: 0.00),
                            .init(color: .black.opacity(0.25), location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    Text(title)
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                        .padding(.top, 40)
                        .padding(.horizontal, 12)
                }
                .frame(width: 200, height: 100)
            }
            
            HStack {
                HStack(spacing: 4) {
                    UserAvatarView(
                        avatarName: author.avatarName,
                        avatarUrl: nil,
                        size: 32,
                        showBorder: false
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(author.name)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("\(attentionCount) Attention")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                PressableFollowButton(
                    blurIntensity: followBlurIntensity,
                    user: author.toBanUserTarget()
                )
            }
            .padding(8)
            .frame(width: 176, height: 40)
            .background {
                AdjustableBlurView(style: .systemUltraThinMaterialLight, intensity: topBarBlurIntensity)
                    .clipShape(Capsule())
            }
            .overlay(
                Capsule()
                    .fill(Color.white.opacity(0.10))
                    .allowsHitTesting(false)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.4), lineWidth: 4)
                    .blur(radius: 5.5)
                    .offset(x: 0, y: 2)
                    .mask(
                        Capsule()
                            .fill(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom))
                    )
                    .clipShape(Capsule())
                    .allowsHitTesting(false)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    .allowsHitTesting(false)
            )
            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
            
            .padding(.leading, 12)
            .padding(.top, 12)
        }
        .frame(width: 200, height: 300)
        .mask(RoundedRectangle(cornerRadius: 16))
    }
}

private struct AdjustableBlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    let intensity: CGFloat
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: nil)
        view.isUserInteractionEnabled = false
        context.coordinator.setEffect(on: view, style: style, intensity: intensity)
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        context.coordinator.setEffect(on: uiView, style: style, intensity: intensity)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    final class Coordinator {
        private var animator: UIViewPropertyAnimator?
        private var lastStyle: UIBlurEffect.Style?
        private var lastIntensity: CGFloat?
        
        deinit {
            cleanupAnimator()
        }
        
        private func cleanupAnimator() {
            guard let animator = animator else { return }
            if animator.state == .active {
                animator.stopAnimation(true)
            }
            if animator.state == .stopped {
                animator.finishAnimation(at: .current)
            }
        }
        
        func setEffect(on view: UIVisualEffectView, style: UIBlurEffect.Style, intensity: CGFloat) {
            let normalizedIntensity = max(0, min(1, intensity))
            if lastStyle == style, lastIntensity == normalizedIntensity {
                return
            }
            cleanupAnimator()
            view.effect = nil
            let blurEffect = UIBlurEffect(style: style)
            let animator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
                view.effect = blurEffect
            }
            animator.fractionComplete = normalizedIntensity
            self.animator = animator
            lastStyle = style
            lastIntensity = normalizedIntensity
        }
    }
}

private struct PressableFollowButton: View {
    let blurIntensity: CGFloat
    let user: BanUserTarget
    @EnvironmentObject private var profileStatsStore: ProfileStatsStore
    @GestureState private var isPressing = false
    
    private var isFollowing: Bool {
        profileStatsStore.isFollowing(user)
    }
    
    var body: some View {
        Text(isFollowing ? "Following" : "Follow")
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(isFollowing ? Color.white.opacity(0.7) : .white)
        .padding(.horizontal, isFollowing ? 10 : 12)
        .padding(.vertical, 4)
        .background {
            AdjustableBlurView(style: .systemUltraThinMaterialLight, intensity: blurIntensity)
                .clipShape(Capsule())
        }
        .overlay(
            Capsule()
                .fill(Color.white.opacity(isFollowing ? 0.2 : 0.12))
                .allowsHitTesting(false)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(isFollowing ? 0.35 : 0.2), lineWidth: isFollowing ? 1.5 : 1)
                .allowsHitTesting(false)
        )
        .shadow(color: .black.opacity(isFollowing ? 0.15 : 0.1), radius: isFollowing ? 10 : 8, x: 0, y: 0)
            .scaleEffect(isPressing ? 0.92 : 1)
            .opacity(isPressing ? 0.8 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressing)
            .contentShape(Capsule())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                .updating($isPressing) { _, state, _ in
                    state = true
                }
            )
        .highPriorityGesture(
            TapGesture()
                .onEnded {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        profileStatsStore.toggleFollow(user: user)
                    }
                }
        )
    }
}

struct HomeHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    ZStack {
        Color(hexString: "1E1E1E")
        HomeHeaderView()
    }
    .environmentObject(BlockedUsersStore())
    .environmentObject(ProfileStatsStore())
}
    }
}
