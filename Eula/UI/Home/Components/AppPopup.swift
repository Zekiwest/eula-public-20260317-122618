import SwiftUI

struct AppPopup<Content: View>: View {
    @Binding var isPresented: Bool
    var content: () -> Content
    
    var body: some View {
        ZStack {
            if isPresented {
                // Dimmed Background
                Color.black.opacity(0.65)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isPresented = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                
                // Popup Content
                content()
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
                    .zIndex(2)
            }
        }
        .zIndex(999) // Ensure it's on top of everything
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPresented)
    }
}

extension View {
    func appPopup<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
        self.overlay(
            AppPopup(isPresented: isPresented, content: content)
        )
    }
}

// Reusable Specific Popup Style (Based on Figma)
struct StarCoinPopup: View {
    var title: String
    var cancelText: String = "CANCEL"
    var sureText: String = "SURE"
    var layoutScale: CGFloat = 1
    var onCancel: () -> Void
    var onSure: () -> Void

    private func innerShadow(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(Color.white.opacity(0.25), lineWidth: 4)
            .blur(radius: 4)
            .mask(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [.black, .clear, .black],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
    }
    
    var body: some View {
        let width: CGFloat = 310 * layoutScale
        let bgHeight: CGFloat = 249 * layoutScale
        let bgTopOffset: CGFloat = 57 * layoutScale

        let starWidth: CGFloat = 254 * layoutScale
        let starHeight: CGFloat = 138 * layoutScale
        let starOffsetX: CGFloat = 28 * layoutScale

        let titleFontSize: CGFloat = 16 * layoutScale
        let buttonFontSize: CGFloat = 16 * layoutScale
        let contentTopPadding: CGFloat = 91 * layoutScale
        let contentBottomPadding: CGFloat = 39 * layoutScale
        let contentHorizontalPadding: CGFloat = 21 * layoutScale
        let contentSpacing: CGFloat = 22 * layoutScale
        let buttonSpacing: CGFloat = 10 * layoutScale
        let buttonWidth: CGFloat = 128 * layoutScale
        let buttonHeight: CGFloat = 48 * layoutScale
        let cornerRadius: CGFloat = 40 * layoutScale

        ZStack {
            Image("popup_bg")
                .resizable()
                .scaledToFill()
                .frame(width: width, height: bgHeight)
                .clipped()

            VStack(spacing: contentSpacing) {
                Text(title)
                    .font(.system(size: titleFontSize, weight: .bold))
                    .foregroundStyle(Color(hexString: "333333"))
                    .lineSpacing(8 * layoutScale)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: buttonSpacing) {
                    Button(action: onCancel) {
                        Text(cancelText)
                            .font(.custom("Notable-Regular", size: buttonFontSize))
                            .foregroundStyle(.white)
                            .frame(width: buttonWidth, height: buttonHeight)
                            .background(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(Color(hexString: "FF8796"))
                            )
                            .overlay(innerShadow(cornerRadius: cornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                            )
                    }

                    Button(action: onSure) {
                        Text(sureText)
                            .font(.custom("Notable-Regular", size: buttonFontSize))
                            .foregroundStyle(.white)
                            .frame(width: buttonWidth, height: buttonHeight)
                            .background(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(Color(hexString: "ACB1D7"))
                            )
                            .overlay(innerShadow(cornerRadius: cornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                            )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.top, contentTopPadding)
            .padding(.bottom, contentBottomPadding)
            .padding(.horizontal, contentHorizontalPadding)
            .frame(width: width, height: bgHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: width, height: bgHeight)
        .overlay(alignment: .topLeading) {
            Image("popup_star")
                .resizable()
                .scaledToFit()
                .frame(width: starWidth, height: starHeight)
                .offset(x: starOffsetX, y: -bgTopOffset)
        }
    }
}
