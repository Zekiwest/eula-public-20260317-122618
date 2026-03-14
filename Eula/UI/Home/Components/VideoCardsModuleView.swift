import SwiftUI
import AVKit
import UIKit

struct VideoCardsModuleView: View {
    let horizontalPadding: CGFloat

    init(horizontalPadding: CGFloat = 16) {
        self.horizontalPadding = horizontalPadding
    }

    var body: some View {
        VideoCardsRowView(showsHeader: true, horizontalPadding: horizontalPadding)
    }
}

struct VideoCardsRowView: View {
    let showsHeader: Bool
    let horizontalPadding: CGFloat
    @EnvironmentObject private var blockedUsersStore: BlockedUsersStore

    init(showsHeader: Bool, horizontalPadding: CGFloat = 16) {
        self.showsHeader = showsHeader
        self.horizontalPadding = horizontalPadding
    }

    var body: some View {
        let cards = MockContent.videoCards.filter { item in
            !blockedUsersStore.isBlocked(item.author.id)
        }
        
        let columns: [GridItem] = [
            GridItem(.flexible(), spacing: 15),
            GridItem(.flexible(), spacing: 15)
        ]

        VStack(alignment: .leading, spacing: 12) {
            if showsHeader {
                Text("VIDEOS")
                    .font(.custom("Notable-Regular", size: 16))
                    .foregroundStyle(.white)
                    .padding(.horizontal, horizontalPadding)
            }

            LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
                ForEach(cards) { item in
                    VideoCardView(item: item)
                }
            }
            .padding(.horizontal, horizontalPadding)
        }
    }
}

private struct VideoCardView: View {
    let item: VideoCardItem

    @State private var isLiked = false
    @State private var isPlaying = false
    @State private var player: AVPlayer?
    @Environment(\.banUserAction) private var banUserAction

    private let baseWidth: CGFloat = 164
    private let baseHeight: CGFloat = 245
    private let baseBottomHeight: CGFloat = 105

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let scale = size.width / baseWidth
            let bottomHeight = size.height * (baseBottomHeight / baseHeight)
            let displayCount = item.likeCount + (isLiked ? 1 : 0)

            ZStack(alignment: .topLeading) {
                mediaLayer(size: size)
                likeButton(scale: scale, displayCount: displayCount)
                contentOverlay(scale: scale, size: size, bottomHeight: bottomHeight)
                moreButton(scale: scale)
                playPauseButton(scale: scale)
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 20 * scale, style: .continuous))
            .overlay {
                if item.showsCardStroke {
                    RoundedRectangle(cornerRadius: 20 * scale, style: .continuous)
                        .stroke(
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(0.6), location: 0),
                                    .init(color: .white.opacity(0), location: 0.22),
                                    .init(color: .white.opacity(0), location: 0.53),
                                    .init(color: .white.opacity(0), location: 0.86),
                                    .init(color: .white.opacity(0.6), location: 1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            }
            .onDisappear {
                player?.pause()
                isPlaying = false
            }
        }
        .aspectRatio(baseWidth / baseHeight, contentMode: .fit)
    }

    private func mediaLayer(size: CGSize) -> some View {
        ZStack {
            Image(item.coverImageName)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()

            if let player {
                VideoCardPlayerView(player: player)
                    .frame(width: size.width, height: size.height)
            }
        }
    }

    private func likeButton(scale: CGFloat, displayCount: Int) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isLiked.toggle()
            }
        } label: {
            HStack(spacing: 6 * scale) {
                if isLiked {
                    Image("heart_select")
                        .resizable()
                        .renderingMode(.original)
                        .frame(width: 16 * scale, height: 16 * scale)
                } else {
                    Image("more_icon_heart")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(.black)
                        .frame(width: 16 * scale, height: 16 * scale)
                }

                RollingNumberText(
                    value: displayCount,
                    fontSize: 14 * scale,
                    color: isLiked ? Color(hexString: "FF8796") : Color(hexString: "333333")
                )
            }
            .padding(.vertical, 4 * scale)
            .padding(.horizontal, 8 * scale)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20 * scale, style: .continuous))
            .scaleEffect(isLiked ? 1.05 : 1)
        }
        .buttonStyle(.plain)
        .padding(.leading, 8 * scale)
        .padding(.top, 8 * scale)
    }

    private func playPauseButton(scale: CGFloat) -> some View {
        Button {
            togglePlay()
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)

                Circle()
                    .fill(Color(hexString: "FF8796").opacity(0.6))

                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14 * scale, weight: .semibold))
                    .foregroundStyle(.white)
                    .offset(x: isPlaying ? 0 : 1 * scale)
            }
            .frame(width: 30 * scale, height: 30 * scale)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func contentOverlay(scale: CGFloat, size: CGSize, bottomHeight: CGFloat) -> some View {
        let seed = MockSeed.stableInt(item.id)
        let followers = MockSeed.compactCount(MockSeed.followerCount(seed: MockSeed.stableInt(item.author.id)))
        return VStack(alignment: .leading, spacing: 2 * scale) {
            Text(MockContent.generatedTitle(seed: seed))
                .font(.system(size: 12 * scale, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.9))

            HStack(spacing: 4 * scale) {
                avatarView(scale: scale)

                VStack(alignment: .leading, spacing: 0) {
                    Text(item.author.name)
                        .font(.system(size: 12 * scale, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.9))

                    Text("\(followers) followers")
                        .font(.system(size: 9 * scale, weight: .light))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
            }
        }
        .padding(.leading, 10 * scale)
        .padding(.top, 15 * scale)
        .padding(.bottom, 10 * scale)
        .frame(width: size.width, height: bottomHeight, alignment: .bottomLeading)
        .background { glassBackground() }
        .clipShape(BottomRoundedRectangle(radius: 20 * scale))
        .frame(width: size.width, height: bottomHeight, alignment: .bottomLeading)
        .offset(y: size.height - bottomHeight)
    }

    private func avatarView(scale: CGFloat) -> some View {
        Image(item.author.avatarName)
            .resizable()
            .scaledToFill()
            .frame(width: 24 * scale, height: 24 * scale)
            .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
            .overlay {
                if item.showsAvatarStroke {
                    RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                        .stroke(
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(0.6), location: 0),
                                    .init(color: .white.opacity(0), location: 0.22),
                                    .init(color: .white.opacity(0), location: 0.53),
                                    .init(color: .white.opacity(0), location: 0.86),
                                    .init(color: .white.opacity(0.6), location: 1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            }
    }

    private func glassBackground() -> some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black.opacity(0.25), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func moreButton(scale: CGFloat) -> some View {
        Button(action: {
            banUserAction?(item.author.toBanUserTarget())
        }) {
            Image("more_icon_dots")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(.white)
                .frame(width: 18 * scale, height: 18 * scale)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.top, 12 * scale)
        .padding(.trailing, 12 * scale)
    }

    private func togglePlay() {
        if player == nil {
            player = makePlayer(assetName: item.videoAssetName)
        }

        guard let player else { return }

        if isPlaying {
            player.pause()
        } else {
            player.play()
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isPlaying.toggle()
        }
    }

    private func makePlayer(assetName: String) -> AVPlayer? {
        guard let url = resolveVideoURL(assetName: assetName) else { return nil }
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.isMuted = true
        newPlayer.actionAtItemEnd = .pause
        return newPlayer
    }

    private func resolveVideoURL(assetName: String) -> URL? {
        if let asset = NSDataAsset(name: assetName, bundle: .main) {
            let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            let fileURL = (cachesURL ?? FileManager.default.temporaryDirectory)
                .appendingPathComponent("\(assetName).mp4")

            let fileSize = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size]) as? NSNumber
            if fileSize?.intValue != asset.data.count {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try? FileManager.default.removeItem(at: fileURL)
                }
                try? asset.data.write(to: fileURL, options: [.atomic])
            }

            return fileURL
        }

        return Bundle.main.url(forResource: assetName, withExtension: "mp4")
    }
}

private struct VideoCardPlayerView: UIViewControllerRepresentable {
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

private struct RollingNumberText: View {
    let value: Int
    let fontSize: CGFloat
    let color: Color

    var body: some View {
        let digits = String(value).map { String($0) }
        let digitHeight = fontSize * 1.5

        HStack(alignment: .center, spacing: 0) {
            ForEach(Array(digits.enumerated()), id: \.offset) { _, digit in
                RollingDigitView(
                    digit: Int(digit) ?? 0,
                    fontSize: fontSize,
                    color: color
                )
            }
        }
        .frame(height: digitHeight)
        .fixedSize(horizontal: true, vertical: true)
    }
}

private struct RollingDigitView: View {
    let digit: Int
    let fontSize: CGFloat
    let color: Color

    private var digitHeight: CGFloat {
        fontSize * 1.5
    }

    private var digitWidth: CGFloat {
        max(fontSize * 0.6, 8)
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                ForEach(0..<10, id: \.self) { number in
                    Text("\(number)")
                        .font(.system(size: fontSize, weight: .regular).monospacedDigit())
                        .foregroundStyle(color)
                        .frame(width: digitWidth, height: digitHeight)
                }
            }
            .offset(y: -CGFloat(digit) * digitHeight)
        }
        .frame(width: digitWidth, height: digitHeight, alignment: .top)
        .clipped()
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: digit)
    }
}

private struct BottomRoundedRectangle: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let r = min(radius, min(rect.width, rect.height) / 2)
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - r))
        path.addArc(
            center: CGPoint(x: rect.width - r, y: rect.height - r),
            radius: r,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: r, y: rect.height))
        path.addArc(
            center: CGPoint(x: r, y: rect.height - r),
            radius: r,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: 0, y: 0))
        return path
    }
}

struct VideoCardsModuleView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    ZStack {
        Color.gray
        VideoCardsModuleView()
    }
    .environmentObject(BlockedUsersStore())
}
    }
}
