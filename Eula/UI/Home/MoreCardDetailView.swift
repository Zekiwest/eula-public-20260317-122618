import SwiftUI
import UIKit

struct MoreCardDetailView: View {
    let item: MoreCardItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarHiddenBinding) private var tabBarHiddenBinding
    @Environment(\.banUserAction) private var banUserAction
    @State private var isSelected = false
    @State private var currentBannerIndex = 0
    @State private var commentText = ""
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isInputFocused: Bool
    @State private var showToast = false
    @State private var toastMessage = ""

    private var galleryImages: [String] {
        MockContent.galleryImages(primaryImageName: item.imageName)
    }
    
    private var authorBio: String {
        let seed = MockSeed.stableInt(item.id)
        let options = [
            "Today’s look is all about soft edges and a glossy finish—kept the base lightweight and let the blush do the work.",
            "Quick routine I’ve been loving lately: skin prep, thin foundation layer, and a lip combo that works with everything.",
            "Tried a new color story today—warm neutrals with a pop of shimmer. Let me know if you want a full product list.",
            "No filter on this one. Focused on skin texture and blending, and finished with a subtle highlight on the high points.",
            "Experimenting with placement: higher blush, softer brows, and a clean liner. It makes the face look so lifted."
        ]
        return options[seed % options.count]
    }

    @State private var comments: [Comment] = MockComments.detail

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / 393, geometry.size.height / 852)
            ZStack(alignment: .top) {
                AppBackground()

                ScrollView {
                    VStack(spacing: 0) {
                        headerView(scale: scale)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            MoreDetailAuthorView(avatarName: item.author.avatarName, name: item.author.name, bio: authorBio)
                            MoreDetailCommentsView(comments: comments)
                        }
                        .padding(.top, 12)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                }
                .scrollIndicators(.hidden)
                .background(ScrollViewBounceDisabler())
                .ignoresSafeArea(edges: .top)
            }
            .overlay {
                if isInputFocused {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isInputFocused = false
                        }
                }
            }
            .overlay(alignment: .bottom) {
                commentInputBar(
                    containerWidth: geometry.size.width,
                    safeAreaBottom: geometry.safeAreaInsets.bottom
                )
            }
            .overlay(alignment: .top) {
                topBar(topInset: geometry.safeAreaInsets.top)
                    .ignoresSafeArea(.container, edges: .top)
            }
            .overlay(alignment: .bottom) {
                if showToast {
                    Text(toastMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.bottom, max(16, keyboardHeight + 16))
                        .transition(.opacity)
                }
            }
        }
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
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return
            }
            let screenHeight: CGFloat
            if #available(iOS 15.0, *) {
                screenHeight = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.screen.bounds.height ?? frame.height
            } else {
                screenHeight = UIScreen.main.bounds.height
            }
            let height = max(0, screenHeight - frame.origin.y)
            withAnimation(keyboardAnimation(from: notification)) {
                keyboardHeight = height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { notification in
            withAnimation(keyboardAnimation(from: notification)) {
                keyboardHeight = 0
            }
        }
    }

    private func headerView(scale: CGFloat) -> some View {
        ZStack(alignment: .top) {
            // Banner Component
            BannerView(
                images: galleryImages,
                height: 433,
                currentIndex: $currentBannerIndex
            )
            .clipShape(RoundedCorner(radius: 30, corners: [.bottomLeft, .bottomRight]))

            // Bottom Elements Overlay
            VStack {
                Spacer()
                ZStack(alignment: .bottom) {
                    // Custom Page Indicator
                    CustomPageControl(
                        numberOfPages: galleryImages.count,
                        currentIndex: $currentBannerIndex
                    )
                    .padding(.bottom, 24) // Adjusted padding for visual balance

                    // Like Button (Floating)
                    HStack {
                        Spacer()
                        let likedColor = Color(hexString: "FF8796")
                        let unlikedColor = Color(hexString: "333333")

                        VerticalIconCountButton(
                            scale: scale,
                            isEnabled: true,
                            count: item.likeCount + (isSelected ? 1 : 0),
                            foregroundColor: isSelected ? likedColor : unlikedColor,
                            action: toggleBannerLike
                        ) {
                            if isSelected {
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
                        .padding(.trailing, 16)
                        .padding(.bottom, 12)
                    }
                }
            }
            .frame(height: 433)
        }
        .frame(height: 433)
    }

    private func topBar(topInset: CGFloat) -> some View {
        HStack {
            AppNavIconButton(imageName: "EULA_BackIcon", action: { dismiss() })

            Spacer()

            AppNavIconButton(imageName: "more_detail_more", action: { banUserAction?(item.author.toBanUserTarget()) })
        }
        .padding(.top, topInset + 10)
        .padding(.horizontal, 16)
    }

    private func keyboardAnimation(from notification: Notification) -> Animation {
        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let curveValue = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int) ?? UIView.AnimationCurve.easeInOut.rawValue
        let curve = UIView.AnimationCurve(rawValue: curveValue) ?? .easeInOut

        switch curve {
        case .easeIn:
            return .easeIn(duration: duration)
        case .easeOut:
            return .easeOut(duration: duration)
        case .linear:
            return .linear(duration: duration)
        case .easeInOut:
            return .easeInOut(duration: duration)
        @unknown default:
            return .easeInOut(duration: duration)
        }
    }

    private func toggleBannerLike() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isSelected.toggle()
        }
    }
}

struct VerticalIconCountButton<Icon: View>: View {
    let scale: CGFloat
    let isEnabled: Bool
    let count: Int
    let foregroundColor: Color
    let action: () -> Void
    @ViewBuilder let icon: () -> Icon

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6 * scale) {
                icon()
                    .frame(width: 24 * scale, height: 24 * scale)

                RollingNumberText(
                    value: count,
                    fontSize: 14 * scale,
                    color: foregroundColor
                )
            }
            .frame(width: 40 * scale)
            .padding(.vertical, 10 * scale)
            .padding(.horizontal, 8 * scale)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20 * scale, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

struct VerticalLikeCommentPanel: View {
    let scale: CGFloat
    let avatarName: String
    let username: String
    @Binding var isLiked: Bool
    let baseLikeCount: Int
    let commentCount: Int
    var likedColor: Color = Color(hexString: "FF8796")
    var unlikedColor: Color = Color(hexString: "333333")
    var onAvatarTap: () -> Void = {}
    var onComment: () -> Void = {}

    var body: some View {
        VStack(spacing: 24 * scale) {
            VStack(spacing: 4 * scale) {
                Button(action: onAvatarTap) {
                    Image(avatarName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52 * scale, height: 52 * scale)
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
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("shorts_avatar_button")
                .accessibilityLabel(username)

                Text(username)
                    .font(.system(size: 16 * scale, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }

            VStack(spacing: 18 * scale) {
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
                    count: commentCount,
                    foregroundColor: unlikedColor,
                    action: onComment
                ) {
                    Image("icon_comments")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundStyle(unlikedColor)
                }
            }
        }
        .frame(width: 58 * scale)
    }

    private func toggleLike() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isLiked.toggle()
        }
    }
}

// MARK: - Subcomponents

private struct MoreDetailAuthorView: View {
    let avatarName: String
    let name: String
    let bio: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // User Info
            HStack(spacing: 14) {
                // Avatar
                Image(avatarName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 54, height: 54)
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
                
                Text(name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            // Content
            Text(bio)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4) // approximate 1.5em line height
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MoreDetailCommentsView: View {
    let comments: [Comment]

    var body: some View {
        AppCommentsSectionView(
            titleCount: comments.count,
            comments: comments,
            showsTrailingMenu: false
        )
    }
}

struct AppCommentsTitleView: View {
    let count: Int

    var body: some View {
        HStack(spacing: 5) {
            Text("\(count) comments")
                .font(.custom("Notable-Regular", size: 16))
                .foregroundStyle(.white)

            Image("more_detail_comment_icon")
                .resizable()
                .frame(width: 42, height: 42)
        }
    }
}

struct AppCommentsSectionView: View {
    let titleCount: Int
    let comments: [Comment]
    let showsTrailingMenu: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppCommentsTitleView(count: titleCount)

            VStack(spacing: 16) {
                ForEach(comments) { comment in
                    AppCommentRowView(comment: comment, showsTrailingMenu: showsTrailingMenu)
                }
            }
        }
    }
}

struct AppCommentRowView: View {
    let comment: Comment
    let showsTrailingMenu: Bool

    var body: some View {
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

                Spacer(minLength: 0)

                if showsTrailingMenu {
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 24)
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()
                .background(Color.white.opacity(0.24))
        }
    }
}

struct AppCommentInputBar: View {
    @Binding var text: String
    let focus: FocusState<Bool>.Binding
    let keyboardHeight: CGFloat
    let containerWidth: CGFloat
    let safeAreaBottom: CGFloat
    let bottomPadding: CGFloat?
    let onSend: () -> Void

    init(
        text: Binding<String>,
        focus: FocusState<Bool>.Binding,
        keyboardHeight: CGFloat = 0,
        containerWidth: CGFloat,
        safeAreaBottom: CGFloat = 0,
        bottomPadding: CGFloat? = nil,
        onSend: @escaping () -> Void
    ) {
        self._text = text
        self.focus = focus
        self.keyboardHeight = keyboardHeight
        self.containerWidth = containerWidth
        self.safeAreaBottom = safeAreaBottom
        self.bottomPadding = bottomPadding
        self.onSend = onSend
    }

    var body: some View {
        let resolvedBottomPadding = bottomPadding ?? max(0, keyboardHeight - safeAreaBottom + 10)

        HStack(spacing: 12) {
            TextField(
                "",
                text: $text,
                prompt: Text("Please enter").foregroundColor(.white.opacity(0.5))
            )
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(.white)
            .focused(focus)

            Button(action: onSend) {
                Image("more_detail_send_icon")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 18)
        .frame(maxWidth: 343)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 35, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .background(
            RoundedRectangle(cornerRadius: 35, style: .continuous)
                .fill(Color.white.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 35, style: .continuous)
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.9), location: 0),
                            .init(color: Color.white.opacity(0.0), location: 0.5),
                            .init(color: Color.white.opacity(0.9), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, max(16, (containerWidth - 343) / 2))
        .padding(.bottom, resolvedBottomPadding)
    }
}

private extension MoreCardDetailView {
    func commentInputBar(containerWidth: CGFloat, safeAreaBottom: CGFloat) -> some View {
        AppCommentInputBar(
            text: $commentText,
            focus: $isInputFocused,
            keyboardHeight: keyboardHeight,
            containerWidth: containerWidth,
            safeAreaBottom: safeAreaBottom,
            onSend: sendComment
        )
    }

    func sendComment() {
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            showToastMessage("Please enter content")
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }

        let newComment = Comment(user: MockProfile.currentUser, content: text)
        comments.append(newComment)
        commentText = ""
        isInputFocused = false

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        showToastMessage("Sent successfully")
    }

    func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation(.easeInOut(duration: 0.2)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showToast = false
            }
        }
    }
}

private struct ScrollViewBounceDisabler: UIViewRepresentable {
    final class Coordinator {
        weak var scrollView: UIScrollView?
        var observation: NSKeyValueObservation?
        private var isSearching = false
        private var searchAttempt = 0
        private let maxSearchAttempts = 5

        func attach(to scrollView: UIScrollView) {
            if self.scrollView === scrollView {
                return
            }

            self.scrollView = scrollView
            self.observation?.invalidate()
            self.observation = scrollView.observe(\.contentOffset, options: [.new]) { scrollView, _ in
                let minY = -scrollView.adjustedContentInset.top
                if scrollView.contentOffset.y < minY {
                    scrollView.setContentOffset(
                        CGPoint(x: scrollView.contentOffset.x, y: minY),
                        animated: false
                    )
                }
            }
        }

        func attachIfNeeded(from uiView: UIView) {
            guard scrollView == nil else { return }
            guard !isSearching else { return }
            isSearching = true
            searchAttempt = 0
            findAndAttach(from: uiView)
        }

        private func findAndAttach(from uiView: UIView) {
            if let root = uiView.findRootSuperview() {
                let scrollViews = root.findSubviews(ofType: UIScrollView.self)
                if let target = scrollViews.first(where: { $0.isScrollEnabled }) {
                    target.bounces = true
                    target.alwaysBounceVertical = true
                    target.alwaysBounceHorizontal = false
                    target.refreshControl = nil
                    attach(to: target)
                    isSearching = false
                    return
                }
            }

            searchAttempt += 1
            guard searchAttempt < maxSearchAttempts else {
                isSearching = false
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self, weak uiView] in
                guard let self, let uiView else { return }
                self.findAndAttach(from: uiView)
            }
        }

        deinit {
            observation?.invalidate()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        UIView(frame: .zero)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.attachIfNeeded(from: uiView)
    }
}

private extension UIView {
    func findRootSuperview() -> UIView? {
        var current: UIView? = self
        while let view = current?.superview {
            current = view
        }
        return current
    }

    func findSubviews<T: UIView>(ofType type: T.Type) -> [T] {
        var results: [T] = []
        var stack: [UIView] = [self]
        while let view = stack.popLast() {
            if let match = view as? T {
                results.append(match)
            }
            stack.append(contentsOf: view.subviews)
        }
        return results
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
                        .foregroundColor(color)
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

struct MoreCardDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    MoreCardDetailView(item: .defaults[0])
}
    }
}
