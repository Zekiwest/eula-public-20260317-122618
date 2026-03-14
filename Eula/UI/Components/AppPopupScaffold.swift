import SwiftUI

struct AppPopupScaffold<Content: View>: View {
    let width: CGFloat
    let height: CGFloat
    @ViewBuilder let content: Content

    init(width: CGFloat = 343, height: CGFloat, @ViewBuilder content: () -> Content) {
        self.width = width
        self.height = height
        self.content = content()
    }

    var body: some View {
        ZStack {
            Image("TermsofUse_bg")
                .resizable(capInsets: EdgeInsets(top: 180, leading: 0, bottom: 150, trailing: 0), resizingMode: .stretch)
                .frame(width: width, height: height)

            content
                .frame(width: width, height: height)
        }
    }
}

struct AppPopupActionButton: View {
    let title: String
    let color: Color
    let width: CGFloat
    let height: CGFloat
    let fontSize: CGFloat
    var hasInnerHighlight: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text(title)
                .font(.custom("Notable-Regular", size: fontSize))
                .foregroundStyle(.white)
                .frame(width: width, height: height)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                )
                .overlay(innerHighlight)
                .shadow(color: .white.opacity(0.25), radius: 4, x: 0, y: 4)
        }
    }

    @ViewBuilder
    private var innerHighlight: some View {
        if hasInnerHighlight {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 4)
                .blur(radius: 2)
                .offset(y: 2)
                .mask(
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .fill(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom))
                )
                .allowsHitTesting(false)
        }
    }
}
