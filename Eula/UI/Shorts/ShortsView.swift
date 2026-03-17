import SwiftUI
import AVKit
import UIKit

struct ShortsView: View {
    private static var cachedBundledVideoURLs: [URL]?
    private static var cachedFallbackVideoURL: URL?

    let isTabSelected: Bool
    
    @Environment(\.tabBarHiddenBinding) private var tabBarHiddenBinding
    @Environment(\.selectedNavTab) private var selectedNavTab
    @Environment(\.selectedNavTabBinding) private var selectedNavTabBinding
    @Environment(\.scenePhase) private var scenePhase

    @State private var path: [ShortsRoute] = []
    @State private var items: [ShortsItem] = []
    @State private var activeIndex = 0
    @State private var isPlaying = true
    @State private var userWantsPlay = true
    @State private var players: [Int: AVPlayer] = [:]
    @State private var playbackEndObservers: [Int: NSObjectProtocol] = [:]
    @State private var playbackStatusObservers: [Int: NSKeyValueObservation] = [:]
    @State private var isCommentsPresented = false
    @State private var commentsTargetID: ShortsItem.ID?
    @State private var lastPlaybackSyncContext: PlaybackSyncContext?
    
    // Figma constants for icon_play
    private let iconSize: CGFloat = 80
    private let iconCornerRadius: CGFloat = 24
    // Color: rgba(255, 135, 150, 0.6) -> R:1, G:0.529, B:0.588
    private let iconColor = Color(red: 1.0, green: 135/255.0, blue: 150/255.0, opacity: 0.6)

    private enum PlaybackIntent: Equatable {
        case play
        case pauseKeep
        case stop
    }

    private struct PlaybackSyncContext: Equatable {
        let intent: PlaybackIntent
        let activeIndex: Int
        let userWantsPlay: Bool
        let hasItems: Bool
    }
    
    init(isTabSelected: Bool = true) {
        self.isTabSelected = isTabSelected
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { proxy in
                let scale = min(proxy.size.width / 393, proxy.size.height / 852)

                ZStack {
                    VerticalPageView(
                        pageCount: items.count,
                        currentIndex: $activeIndex,
                        activeIndex: activeIndex
                    ) { index in
                        AnyView(
                            shortsPage(
                                item: items[index],
                                index: index,
                                proxy: proxy,
                                scale: scale,
                                isActive: index == activeIndex
                            )
                        )
                    }
                    .ignoresSafeArea()
                    
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 255 / 255.0, green: 135 / 255.0, blue: 150 / 255.0),
                            Color(red: 255 / 255.0, green: 135 / 255.0, blue: 150 / 255.0).opacity(0)
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 159 * scale)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea()
                }
                .onAppear {
                    loadItemsIfNeeded()
                    if !items.isEmpty {
                        activeIndex = min(max(0, activeIndex), items.count - 1)
                        activateCurrentItem()
                    }
                }
                .onChange(of: activeIndex, perform: { _ in
                    if playbackIntent() == .play {
                        activateCurrentItem()
                    }
                })
            }
            .navigationBarHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(for: ShortsRoute.self) { destination(for: $0) }
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                tabBarHiddenBinding?.wrappedValue = false
            }
            loadItemsIfNeeded()
            if !items.isEmpty {
                activeIndex = min(max(0, activeIndex), items.count - 1)
            }
            syncPlayback(force: true)
        }
        .onDisappear {
            pauseKeepFrame()
            lastPlaybackSyncContext = nil
        }
        .onChange(of: path, perform: { _ in
            syncPlayback()
        })
        .onChange(of: selectedNavTab, perform: { _ in
            syncPlayback()
        })
        .onChange(of: selectedNavTabBinding?.wrappedValue, perform: { _ in
            syncPlayback()
        })
        .onChange(of: isTabSelected, perform: { _ in
            syncPlayback()
        })
        .onChange(of: scenePhase, perform: { _ in
            syncPlayback()
        })
        .onChange(of: isCommentsPresented, perform: { _ in
            syncPlayback()
        })
        .sheet(isPresented: $isCommentsPresented) { commentsSheet() }
    }

    @ViewBuilder
    private func destination(for route: ShortsRoute) -> some View {
        switch route {
        case let .personalHomepage(user, profilePhotosBackgroundName):
            otherProfileViewDestination(user: user, photoRowImageName: profilePhotosBackgroundName, onMakeupTap: {
                path.append(.makeupVideo)
            })
        case .makeupVideo:
            MakeupVideoView()
        }
    }

    @ViewBuilder
    private func commentsSheet() -> some View {
        if let id = commentsTargetID {
            ShortsCommentsSheet(comments: bindingForComments(id: id))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.clear)
        } else {
            EmptyView()
        }
    }
    
    private func shortsPage(item: ShortsItem, index: Int, proxy: GeometryProxy, scale: CGFloat, isActive: Bool) -> some View {
        let tabBarTopFromBottom = proxy.safeAreaInsets.bottom + (25 * scale) + (62 * scale)
        let tabBarLeading = max((proxy.size.width - (333 * scale)) / 2, 0)

        return ZStack(alignment: .bottomTrailing) {
            if let player = players[index] {
                VideoPlayerView(player: player)
                    .ignoresSafeArea()
                    .onTapGesture { 
                        if isActive { togglePlay() }
                    }
            } else {
                Color.black.ignoresSafeArea()
            }

            Text(item.caption)
                .font(.system(size: 16 * scale, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.9))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.leading, tabBarLeading)
                .padding(.bottom, tabBarTopFromBottom + (10 * scale))

            VStack {
                Spacer()

                VerticalLikeCommentPanel(
                    scale: scale,
                    avatarName: item.profileUser.avatarName,
                    username: item.profileUser.name,
                    isLiked: bindingForIsLiked(id: item.id),
                    baseLikeCount: item.baseLikeCount,
                    commentCount: item.comments.count,
                    onAvatarTap: {
                        path.append(.personalHomepage(user: item.profileUser, profilePhotosBackgroundName: item.profilePhotosBackgroundName))
                    },
                    onComment: {
                        commentsTargetID = item.id
                        isCommentsPresented = true
                    }
                )
                .padding(.trailing, max(16, proxy.safeAreaInsets.trailing + 16))
                .padding(.bottom, max(16, proxy.safeAreaInsets.bottom + (183 * scale)))
            }
            .frame(maxWidth: (40 * scale), maxHeight: .infinity, alignment: .bottomTrailing)

            if isActive, !isPlaying {
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
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func loadItemsIfNeeded() {
        guard items.isEmpty else { return }
        let urls = resolveBundledVideoURLs()
        let fallbackURL = resolveFallbackVideoURL()
        let videoURLs = urls.isEmpty ? (fallbackURL.map { [$0] } ?? []) : urls
        items = MockShorts.items(videoURLs: videoURLs)
    }

    private func resolveBundledVideoURLs() -> [URL] {
        if let cached = Self.cachedBundledVideoURLs {
            return cached
        }

        let dataAssetURLs = resolveVideoDataAssetURLs()
        if !dataAssetURLs.isEmpty {
            Self.cachedBundledVideoURLs = dataAssetURLs
            return dataAssetURLs
        }

        let candidates: [(String?, String?)] = [
            ("mp4", "video_data"),
            ("mov", "video_data"),
            ("m4v", "video_data")
        ]

        var urls: [URL] = []
        for (ext, subdir) in candidates {
            urls.append(contentsOf: Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: subdir) ?? [])
        }

        if urls.isEmpty {
            let fallbackCandidates: [(String?, String?)] = [
                ("mp4", "Assets/video_data"),
                ("mov", "Assets/video_data"),
                ("m4v", "Assets/video_data")
            ]
            for (ext, subdir) in fallbackCandidates {
                urls.append(contentsOf: Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: subdir) ?? [])
            }
        }

        let resolved = Array(Set(urls)).sorted { $0.lastPathComponent < $1.lastPathComponent }
        Self.cachedBundledVideoURLs = resolved
        return resolved
    }

    private func resolveVideoDataAssetURLs() -> [URL] {
        let baseDirectory = preferredVideoStorageDirectory()

        var urls: [URL] = []
        for index in 1...30 {
            let names = ["\(index)", "video_data/\(index)"]
            guard let asset = names.compactMap({ NSDataAsset(name: $0, bundle: .main) }).first else {
                continue
            }

            if let url = writeDataAssetToPlayableFile(data: asset.data, fileName: "shorts_video_data_\(index).mp4", preferredDirectory: baseDirectory) {
                urls.append(url)
            }
        }

        return urls
    }

    private func resolveFallbackVideoURL() -> URL? {
        if let cached = Self.cachedFallbackVideoURL {
            return cached
        }

        if let asset = resolveShortsVideoDataAsset() {
            let baseDirectory = preferredVideoStorageDirectory()
            let resolved = writeDataAssetToPlayableFile(data: asset.data, fileName: "shorts_video.mp4", preferredDirectory: baseDirectory)
            Self.cachedFallbackVideoURL = resolved
            return resolved
        }

        let resolved = Bundle.main.url(forResource: "shorts_video", withExtension: "mp4")
        Self.cachedFallbackVideoURL = resolved
        return resolved
    }

    private func resolveShortsVideoDataAsset() -> NSDataAsset? {
        #if targetEnvironment(simulator)
        if let asset = NSDataAsset(name: "shorts_video_sim", bundle: .main) {
            return asset
        }
        #endif
        return NSDataAsset(name: "shorts_video", bundle: .main)
    }

    private func preferredVideoStorageDirectory() -> URL {
        let fileManager = FileManager.default
        guard let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return fileManager.temporaryDirectory
        }

        let directory = base.appendingPathComponent("ShortsVideos", isDirectory: true)
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            return directory
        } catch {
            #if DEBUG
            print("[Shorts] createDirectory failed url=\(directory.path) err=\(error)")
            #endif
            return fileManager.temporaryDirectory
        }
    }

    private func activateCurrentItem() {
        guard activeIndex >= 0, activeIndex < items.count else {
            stopAllPlayback()
            isPlaying = false
            return
        }

        preloadAdjacentVideos()
        
        if let player = players[activeIndex] {
            if userWantsPlay, playbackIntent() == .play {
                configureVideoAudioSession()
                player.playImmediately(atRate: 1.0)
                isPlaying = true
            }
        } else {
            activateVideo(at: activeIndex, shouldPlay: true)
        }
    }
    
    private func preloadAdjacentVideos() {
        let indices = [activeIndex - 1, activeIndex, activeIndex + 1]
        
        for index in indices {
            guard index >= 0, index < items.count else { continue }
            if players[index] == nil {
                activateVideo(at: index, shouldPlay: false)
            }
        }
        
        let indicesToKeep = Set(indices.filter { $0 >= 0 && $0 < items.count })
        for (index, _) in players {
            if !indicesToKeep.contains(index) {
                stopPlayback(at: index)
            }
        }
    }

    private func activateVideo(at index: Int, shouldPlay: Bool) {
        guard index >= 0, index < items.count else { return }
        
        let url = items[index].videoURL
        
        if players[index] != nil {
            stopPlayback(at: index)
        }
        
        if shouldPlay, playbackIntent() == .play {
            configureVideoAudioSession()
        }

        let urlAsset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: urlAsset)
        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.actionAtItemEnd = .pause
        
        let statusObserver = item.observe(\.status, options: [.initial, .new]) { [weak newPlayer] item, _ in
            guard let newPlayer else { return }
            Task { @MainActor in
                switch item.status {
                case .readyToPlay:
                    if shouldPlay, index == self.activeIndex, self.userWantsPlay, self.playbackIntent() == .play {
                        newPlayer.playImmediately(atRate: 1.0)
                        self.isPlaying = true
                    }
                case .failed:
                    if index == self.activeIndex {
                        self.isPlaying = false
                    }
                default:
                    break
                }
            }
        }
        playbackStatusObservers[index] = statusObserver
        
        let endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak newPlayer] _ in
            guard let newPlayer else { return }
            Task { @MainActor in
                guard self.players[index] === newPlayer else { return }
                if index == self.activeIndex, self.playbackIntent() == .play, self.isPlaying {
                    newPlayer.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                        Task { @MainActor in
                            guard self.players[index] === newPlayer else { return }
                            if index == self.activeIndex, self.playbackIntent() == .play {
                                newPlayer.play()
                            }
                        }
                    }
                }
            }
        }
        playbackEndObservers[index] = endObserver
        
        players[index] = newPlayer
        newPlayer.pause()
        
        if index == activeIndex {
            isPlaying = false
        }
    }

    private func stopPlayback(at index: Int) {
        if let endObserver = playbackEndObservers[index] {
            NotificationCenter.default.removeObserver(endObserver)
            playbackEndObservers.removeValue(forKey: index)
        }
        playbackStatusObservers[index]?.invalidate()
        playbackStatusObservers.removeValue(forKey: index)
        players[index]?.pause()
        players[index]?.cancelPendingPrerolls()
        players[index]?.replaceCurrentItem(with: nil)
        players.removeValue(forKey: index)
    }
    
    private func stopAllPlayback() {
        for index in players.keys {
            stopPlayback(at: index)
        }
    }
    
    private func pauseKeepFrame() {
        players[activeIndex]?.pause()
        players[activeIndex]?.cancelPendingPrerolls()
        isPlaying = false
    }

    private func playbackIntent() -> PlaybackIntent {
        if !isTabSelected || selectedNavTab != .shorts {
            return .pauseKeep
        }

        if scenePhase != .active {
            return .stop
        }

        if !path.isEmpty {
            return .stop
        }

        if isCommentsPresented {
            return .pauseKeep
        }

        return .play
    }

    private func syncPlayback(force: Bool = false) {
        let context = PlaybackSyncContext(
            intent: playbackIntent(),
            activeIndex: activeIndex,
            userWantsPlay: userWantsPlay,
            hasItems: !items.isEmpty
        )
        if !force, context == lastPlaybackSyncContext {
            return
        }
        lastPlaybackSyncContext = context

        switch context.intent {
        case .play:
            loadItemsIfNeeded()
            if !items.isEmpty {
                activeIndex = min(max(0, activeIndex), items.count - 1)
            }

            if players[activeIndex] == nil {
                activateCurrentItem()
            } else {
                if userWantsPlay {
                    configureVideoAudioSession()
                    if players[activeIndex]?.timeControlStatus != .playing {
                        players[activeIndex]?.playImmediately(atRate: 1.0)
                    }
                    isPlaying = true
                } else {
                    players[activeIndex]?.pause()
                    isPlaying = false
                }
            }

        case .pauseKeep:
            pauseKeepFrame()

        case .stop:
            stopAllPlayback()
            isPlaying = false
        }
    }
    
    private func togglePlay() {
        guard let player = players[activeIndex] else { return }
        userWantsPlay.toggle()
        if userWantsPlay, playbackIntent() == .play {
            configureVideoAudioSession()
            player.playImmediately(atRate: 1.0)
        } else {
            player.pause()
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isPlaying = userWantsPlay && playbackIntent() == .play
        }
    }
    
    private func configureVideoAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback, options: [])
        try? session.setActive(true, options: [])
    }
    
    private func writeDataAssetToPlayableFile(data: Data, fileName: String, preferredDirectory: URL) -> URL? {
        let fileURL = preferredDirectory.appendingPathComponent(fileName)
        
        let existingSize = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size]) as? NSNumber
        if existingSize?.intValue == data.count {
            return fileURL
        }
        
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            try data.write(to: fileURL, options: [.atomic])
            do {
                try FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: fileURL.path)
            } catch {
                #if DEBUG
                print("[Shorts] setAttributes failed url=\(fileURL.path) err=\(error)")
                #endif
            }
            
            let finalSize = (try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size]) as? NSNumber
            guard finalSize?.intValue == data.count else { return nil }
            return fileURL
        } catch {
            let altURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            do {
                if FileManager.default.fileExists(atPath: altURL.path) {
                    try FileManager.default.removeItem(at: altURL)
                }
                try data.write(to: altURL, options: [.atomic])
                do {
                    try FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: altURL.path)
                } catch {
                    #if DEBUG
                    print("[Shorts] setAttributes failed url=\(altURL.path) err=\(error)")
                    #endif
                }
                let finalSize = (try FileManager.default.attributesOfItem(atPath: altURL.path)[.size]) as? NSNumber
                guard finalSize?.intValue == data.count else { return nil }
                return altURL
            } catch {
                return nil
            }
        }
    }

    private func bindingForIsLiked(id: ShortsItem.ID) -> Binding<Bool> {
        Binding(
            get: { items.first(where: { $0.id == id })?.isLiked ?? false },
            set: { newValue in
                guard let index = items.firstIndex(where: { $0.id == id }) else { return }
                items[index].isLiked = newValue
            }
        )
    }

    private func bindingForComments(id: ShortsItem.ID) -> Binding<[Comment]> {
        Binding(
            get: { items.first(where: { $0.id == id })?.comments ?? [] },
            set: { newValue in
                guard let index = items.firstIndex(where: { $0.id == id }) else { return }
                items[index].comments = newValue
            }
        )
    }
}

private struct VerticalPageView: UIViewControllerRepresentable {
    let pageCount: Int
    @Binding var currentIndex: Int
    let activeIndex: Int
    let pageBuilder: (Int) -> AnyView

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .vertical
        )
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        context.coordinator.rebuildControllersIfNeeded(
            pageCount: pageCount,
            activeIndex: activeIndex,
            pageBuilder: pageBuilder
        )
        if let initial = context.coordinator.controller(at: currentIndex) {
            controller.setViewControllers([initial], direction: .forward, animated: false)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        context.coordinator.parent = self
        context.coordinator.rebuildControllersIfNeeded(
            pageCount: pageCount,
            activeIndex: activeIndex,
            pageBuilder: pageBuilder
        )
        context.coordinator.updateVisibleControllerIfNeeded(pageViewController: uiViewController)
    }

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: VerticalPageView
        var controllers: [UIViewController] = []

        init(_ parent: VerticalPageView) {
            self.parent = parent
        }

        func rebuildControllersIfNeeded(pageCount: Int, activeIndex: Int, pageBuilder: (Int) -> AnyView) {
            guard controllers.count == pageCount else {
                controllers = (0..<pageCount).map { index in
                    let hosting = UIHostingController(rootView: pageBuilder(index))
                    hosting.view.backgroundColor = .clear
                    return hosting
                }
                return
            }

            guard !controllers.isEmpty else { return }
            let target = min(max(0, activeIndex), controllers.count - 1)
            let low = max(0, target - 1)
            let high = min(controllers.count - 1, target + 1)
            for index in low...high {
                guard let hosting = controllers[index] as? UIHostingController<AnyView> else { continue }
                hosting.rootView = pageBuilder(index)
            }
        }

        func controller(at index: Int) -> UIViewController? {
            guard index >= 0, index < controllers.count else { return nil }
            return controllers[index]
        }

        func index(of viewController: UIViewController) -> Int? {
            controllers.firstIndex(where: { $0 === viewController })
        }

        func updateVisibleControllerIfNeeded(pageViewController: UIPageViewController) {
            guard let target = controller(at: parent.currentIndex) else { return }
            guard let visible = pageViewController.viewControllers?.first else {
                pageViewController.setViewControllers([target], direction: .forward, animated: false)
                return
            }

            if visible !== target {
                let visibleIndex = index(of: visible) ?? 0
                let direction: UIPageViewController.NavigationDirection = parent.currentIndex >= visibleIndex ? .forward : .reverse
                pageViewController.setViewControllers([target], direction: direction, animated: false)
            }
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let index = index(of: viewController) else { return nil }
            return controller(at: index - 1)
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let index = index(of: viewController) else { return nil }
            return controller(at: index + 1)
        }

        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            guard completed, let visible = pageViewController.viewControllers?.first, let index = index(of: visible) else { return }
            parent.currentIndex = index
        }
    }
}

private enum ShortsRoute: Hashable {
    case personalHomepage(user: BanUserTarget, profilePhotosBackgroundName: String)
    case makeupVideo
}

private struct VideoPlayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.playerLayer.videoGravity = .resizeAspectFill
        view.playerLayer.player = player
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
    }
    
    static func dismantleUIView(_ uiView: PlayerContainerView, coordinator: ()) {
        uiView.playerLayer.player?.pause()
        uiView.playerLayer.player = nil
    }
}

private final class PlayerContainerView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
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
            cleanupAnimator()
            view.effect = nil
            let blurEffect = UIBlurEffect(style: style)
            let animator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
                view.effect = blurEffect
            }
            animator.fractionComplete = max(0, min(1, intensity))
            self.animator = animator
        }
    }
}

struct ShortsCommentsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.banUserAction) private var banUserAction
    @Binding var comments: [Comment]
    @State private var commentText = ""
    @FocusState private var isInputFocused: Bool
    private let sheetBackgroundOpacity: CGFloat = 0.5
    private let sheetBlurIntensity: CGFloat = 0.6
    private let sheetBlurStyle: UIBlurEffect.Style = .systemUltraThinMaterialDark

    var body: some View {
        GeometryReader { geometry in
            let containerWidth = geometry.size.width
            let bottomInset = geometry.safeAreaInsets.bottom

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 36, height: 4)
                    .padding(.top, 8)

                header
                    .padding(.top, 8)
                    .padding(.horizontal, 16)

                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(comments) { comment in
                            commentRow(comment)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)

                inputBar(containerWidth: containerWidth, bottomInset: bottomInset)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(
                ZStack {
                    AdjustableBlurView(style: sheetBlurStyle, intensity: sheetBlurIntensity)
                    Color.black.opacity(sheetBackgroundOpacity)
                }
            )
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    private var header: some View {
        HStack(spacing: 5) {
            Text("\(comments.count) comments")
                .font(.custom("Notable-Regular", size: 16))
                .foregroundStyle(.white)

            Image("more_detail_comment_icon")
                .resizable()
                .frame(width: 42, height: 42)

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
    }

    private func commentRow(_ comment: Comment) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 9) {
                Image(comment.avatarName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
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

                VStack(alignment: .leading, spacing: 0) {
                    Text(comment.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(height: 24)

                    Text(comment.content)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineSpacing(2)
                }

                Spacer()

                Button(action: {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        banUserAction?(comment.user.toBanUserTarget())
                    }
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }

            Divider()
                .background(Color.white.opacity(0.24))
        }
    }

    private func inputBar(containerWidth: CGFloat, bottomInset: CGFloat) -> some View {
        AppCommentInputBar(
            text: $commentText,
            focus: $isInputFocused,
            containerWidth: containerWidth,
            bottomPadding: max(16, bottomInset + 8),
            onSend: sendComment
        )
    }

    private func sendComment() {
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let newComment = Comment(user: MockProfile.currentUser, content: text)
        comments.append(newComment)
        commentText = ""
        isInputFocused = false
    }
}

struct ShortsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    ShortsView()
}
    }
}
