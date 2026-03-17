import SwiftUI

struct MoreModuleView: View {
    var body: some View {
        MoreCardsGridView(showsHeader: true)
    }
}

struct MoreCardsGridView: View {
    let showsHeader: Bool
    @EnvironmentObject private var blockedUsersStore: BlockedUsersStore

    init(showsHeader: Bool) {
        self.showsHeader = showsHeader
    }

    var body: some View {
        let cards = MoreCardItem.defaults.filter { item in
            !blockedUsersStore.isBlocked(item.authorId)
        }
        VStack(alignment: .leading, spacing: 12) {
            if showsHeader {
                HStack {
                    Text("More")
                        .font(.custom("Notable-Regular", size: 16))
                        .foregroundColor(.white)

                    Spacer()

                    HStack(spacing: 4) {
                        Text("View all")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.white.opacity(0.75))

                        Image("more_icon_arrow")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(.white.opacity(0.75))
                            .frame(width: 12, height: 12)
                    }
                }
                .padding(.horizontal, 16)
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 16
            ) {
                ForEach(cards) { item in
                    NavigationLink(destination: MoreCardDetailView(item: item)) {
                        MoreCardView(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct MoreCardView: View {
    let item: MoreCardItem
    @State private var isSelected = false
    @Environment(\.banUserAction) private var banUserAction

    private let baseWidth: CGFloat = 164
    private let baseHeight: CGFloat = 246
    private let baseBottomHeight: CGFloat = 105

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let scale = size.width / baseWidth
            let bottomHeight = size.height * (baseBottomHeight / baseHeight)
            let displayCount = item.baseCount + (isSelected ? 1 : 0)

            ZStack(alignment: .topLeading) {
                backgroundImage(size: size)
                likeButton(scale: scale, displayCount: displayCount)
                contentOverlay(scale: scale, size: size, bottomHeight: bottomHeight)
                moreButton(scale: scale)
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))
            .overlay {
                if item.showsCardStroke {
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
        .aspectRatio(baseWidth / baseHeight, contentMode: .fit)
    }

    private func backgroundImage(size: CGSize) -> some View {
        Image(item.imageName)
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .clipped()
    }

    private func likeButton(scale: CGFloat, displayCount: Int) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isSelected.toggle()
            }
        } label: {
            HStack(spacing: 6 * scale) {
                if isSelected {
                    Image("heart_select")
                        .resizable()
                        .renderingMode(.original)
                        .frame(width: 16 * scale, height: 16 * scale)
                } else {
                    Image("more_icon_heart")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.black)
                        .frame(width: 16 * scale, height: 16 * scale)
                }

                RollingNumberText(
                    value: displayCount,
                    fontSize: 14 * scale,
                    color: isSelected ? Color(hexString: "FF8796") : Color(hexString: "333333")
                )
            }
            .padding(.vertical, 4 * scale)
            .padding(.horizontal, 8 * scale)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20 * scale, style: .continuous))
            .scaleEffect(isSelected ? 1.05 : 1)
        }
        .buttonStyle(.plain)
        .padding(.leading, 8 * scale)
        .padding(.top, 8 * scale)
    }

    private func contentOverlay(scale: CGFloat, size: CGSize, bottomHeight: CGFloat) -> some View {
        let seed = MockSeed.stableInt(item.id)
        let followers = MockSeed.compactCount(MockSeed.followerCount(seed: MockSeed.stableInt(item.authorId)))
        return VStack(alignment: .leading, spacing: 2 * scale) {
            Text(MockContent.generatedTitle(seed: seed))
                .font(.system(size: 15 * scale, weight: .black))
                .foregroundColor(.white.opacity(0.9))

            HStack(spacing: 4 * scale) {
                avatarView(scale: scale)

                VStack(alignment: .leading, spacing: 0) {
                    Text(item.authorName)
                        .font(.system(size: 12 * scale, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))

                    Text("\(followers) followers")
                        .font(.system(size: 9 * scale, weight: .light))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(.leading, 9.5 * scale)
        .padding(.top, 15 * scale)
        .padding(.bottom, 10 * scale)
        .frame(width: size.width, height: bottomHeight, alignment: .bottomLeading)
        .background {
            glassBackground()
        }
        .clipShape(BottomRoundedRectangle(radius: 16 * scale))
        .frame(width: size.width, height: bottomHeight, alignment: .bottomLeading)
        .offset(y: size.height - bottomHeight)
    }

    private func avatarView(scale: CGFloat) -> some View {
        Image(item.authorAvatarName)
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
            banUserAction?(BanUserTarget(id: item.authorId, name: item.authorName, avatarName: item.authorAvatarName))
        }) {
            Image("more_icon_dots")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(.white)
                .frame(width: 18 * scale, height: 18 * scale)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.top, 12 * scale)
        .padding(.trailing, 12 * scale)
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

struct MoreModuleView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    ZStack {
        Color.gray
        MoreModuleView()
    }
    .environmentObject(BlockedUsersStore())
}
    }
}
