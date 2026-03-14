import SwiftUI

struct AuthFormSection<Content: View>: View {
    let title: String
    let scale: CGFloat
    @ViewBuilder let content: Content

    init(title: String, scale: CGFloat, @ViewBuilder content: () -> Content) {
        self.title = title
        self.scale = scale
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 56 * scale) {
            Text(title)
                .font(.custom("Notable-Regular", size: 32 * scale))
                .foregroundColor(.white)

            VStack(spacing: 16 * scale) {
                content
            }
        }
        .frame(width: 332 * scale, alignment: .leading)
    }
}

struct AuthPrimaryActionButton: View {
    let title: String
    let scale: CGFloat
    let isEnabled: Bool
    var isLoading: Bool = false
    var loadingTitle: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    HStack(spacing: 8 * scale) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.9)
                        Text(loadingTitle ?? title)
                    }
                } else {
                    Text(title)
                }
            }
            .font(.custom("Notable-Regular", size: 16 * scale))
            .foregroundColor(.white.opacity(isEnabled && !isLoading ? 1 : 0.6))
            .frame(width: 210 * scale, height: 53 * scale)
            .background(buttonBackground)
            .cornerRadius(40 * scale)
            .overlay(
                RoundedRectangle(cornerRadius: 40 * scale)
                    .stroke(Color.white.opacity(isEnabled ? 0.4 : 0.2), lineWidth: 2)
            )
        }
        .disabled(!isEnabled || isLoading)
    }

    private var buttonBackground: some View {
        Group {
            if isEnabled {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.5059, green: 0.7843, blue: 0.8627),
                        Color(red: 0.9686, green: 0.6980, blue: 0.3412),
                        Color(red: 1.0, green: 0.5294, blue: 0.5882),
                        Color(red: 0.6745, green: 0.6941, blue: 0.8431)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else {
                Color.white.opacity(0.2)
            }
        }
    }
}
