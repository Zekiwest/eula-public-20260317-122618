import SwiftUI
import AVKit

struct MakeupVideoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarHiddenBinding) private var tabBarHiddenBinding
    @Environment(\.banUserAction) private var banUserAction

    @State private var isPlaying = true
    @State private var player: AVPlayer?
    @State private var isLiked = false
    @State private var baseLikeCount = MockSeed.likeCount(seed: MockSeed.stableInt("makeup_video"))
    @State private var comments: [Comment] = MockComments.detail
    @State private var isCommentsPresented = false
    @State private var isDismissing = false
    @State private var playerLoopObserver: NSObjectProtocol?
    
    // Figma constants for icon_play
    private let iconSize: CGFloat = 80
    private let iconCornerRadius: CGFloat = 24
    // Color: rgba(255, 135, 150, 0.6) -> R:1, G:0.529, B:0.588
    private let iconColor = Color(red: 1.0, green: 135/255.0, blue: 150/255.0, opacity: 0.6)

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / 393, proxy.size.height / 852)
            let tabBarBottomPadding = max((34 * scale) - proxy.safeAreaInsets.bottom, 0)
            let tabBarTopFromBottom = proxy.safeAreaInsets.bottom + tabBarBottomPadding + 56
            let tabBarLeading = max((proxy.size.width - 327) / 2, 0)

            ZStack(alignment: .bottomTrailing) {
                // Video Player Background
                if let player = player {
                    MakeupVideoPlayerView(player: player)
                        .ignoresSafeArea()
                        .onTapGesture {
                            togglePlay()
                        }
                } else {
                    Color.black.ignoresSafeArea()
                }

                // Gradient Overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 255/255.0, green: 135/255.0, blue: 150/255.0),
                        Color(red: 255/255.0, green: 135/255.0, blue: 150/255.0).opacity(0)
                    ]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 159 * scale)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

                // Text Content
                Text(MockContent.generatedTitle(seed: MockSeed.stableInt("makeup_video_title")))
                    .font(.system(size: 16 * scale, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(.leading, tabBarLeading)
                    .padding(.bottom, tabBarTopFromBottom + (10 * scale))

                // Right Side Panel (Like & Comment only, no Avatar)
                VStack(spacing: 18 * scale) {
                    let likedColor = Color(hexString: "FF8796")
                    let unlikedColor = Color(hexString: "333333")
                    
                    VerticalIconCountButton(
                        scale: scale,
                        isEnabled: true,
                        count: baseLikeCount + (isLiked ? 1 : 0),
                        foregroundColor: isLiked ? likedColor : unlikedColor,
                        action: toggleLike
                    ) {
                        if isLiked {
                            Image("heart_select")
                                .resizable()
                                .renderingMode(.original)
                        } else {
                            Image("more_icon_heart")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundStyle(unlikedColor)
                        }
                    }

                    VerticalIconCountButton(
                        scale: scale,
                        isEnabled: true,
                        count: comments.count,
                        foregroundColor: unlikedColor,
                        action: { isCommentsPresented = true }
                    ) {
                        Image("icon_comments")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .foregroundStyle(unlikedColor)
                    }
                }
                .padding(.trailing, max(16, proxy.safeAreaInsets.trailing + 16))
                .padding(.bottom, max(16, proxy.safeAreaInsets.bottom + (183 * scale)))
                .frame(maxWidth: (40 * scale), maxHeight: .infinity, alignment: .bottomTrailing)

                // Play/Pause Icon Overlay
                if !isPlaying {
                    Button(action: togglePlay) {
                        ZStack {
                            RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous)
                                .fill(.ultraThinMaterial)

                            RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous)
                                .fill(iconColor)

                            Image(systemName: "play.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .offset(x: 2)
                                .foregroundStyle(.white)
                        }
                        .frame(width: iconSize, height: iconSize)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                }
                
                // Top Bar (Back & More)
                AppTopBar(
                    topInset: proxy.safeAreaInsets.top,
                    leadingIconName: "EULA_BackIcon",
                    trailingIconName: "more_detail_more",
                    onLeadingTap: {
                        guard !isDismissing else { return }
                        isDismissing = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    },
                    onTrailingTap: { banUserAction?(MockProfile.currentUser.toBanUserTarget()) }
                )
                .ignoresSafeArea(.container, edges: .top)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .background(TabBarVisibilitySync())
        .navigationBarHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            tabBarHiddenBinding?.wrappedValue = true
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            if let playerLoopObserver {
                NotificationCenter.default.removeObserver(playerLoopObserver)
                self.playerLoopObserver = nil
            }
            tabBarHiddenBinding?.wrappedValue = false
        }
        .sheet(isPresented: $isCommentsPresented) {
            ShortsCommentsSheet(comments: $comments)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.clear)
        }
    }
    
    private func setupPlayer() {
        guard player == nil else {
            player?.play()
            isPlaying = true
            return
        }

        guard let videoURL = resolveVideoURL() else {
            isPlaying = false
            return
        }

        let playerItem = AVPlayerItem(url: videoURL)
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.actionAtItemEnd = .none // Prevent pause at end

        if let playerLoopObserver {
            NotificationCenter.default.removeObserver(playerLoopObserver)
            self.playerLoopObserver = nil
        }

        playerLoopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            playerItem.seek(to: .zero, completionHandler: nil)
        }
        
        self.player = newPlayer
        newPlayer.play()
        isPlaying = true
    }

    private func resolveVideoURL() -> URL? {
        if let asset = NSDataAsset(name: "shorts_video", bundle: .main) {
            let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            let fileURL = (cachesURL ?? FileManager.default.temporaryDirectory)
                .appendingPathComponent("shorts_video.mp4")

            let fileSize = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size]) as? NSNumber
            if fileSize?.intValue != asset.data.count {
                do {
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        try FileManager.default.removeItem(at: fileURL)
                    }
                    try asset.data.write(to: fileURL, options: [.atomic])
                } catch {
                    print("Error writing shorts_video asset to disk: \(error)")
                    return nil
                }
            }

            return fileURL
        }

        return Bundle.main.url(forResource: "shorts_video", withExtension: "mp4")
    }
    
    private func togglePlay() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isPlaying.toggle()
        }
    }
    
    private func toggleLike() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isLiked.toggle()
        }
    }
}

// Reusing VideoPlayerView structure but renaming to avoid conflict if in same scope (though private in other file is fine, being explicit helps)
private struct MakeupVideoPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        controller.view.backgroundColor = .clear
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player !== player {
            uiViewController.player = player
        }
    }
}

struct MakeupVideoView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    MakeupVideoView()
}
    }
}
