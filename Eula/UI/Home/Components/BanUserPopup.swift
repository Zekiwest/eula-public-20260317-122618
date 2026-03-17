import SwiftUI

struct BanUserPopup: View {
    var onReport: () -> Void
    var onBlock: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        AppPopupScaffold(height: 302) {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    AppPopupActionButton(
                        title: "Report",
                        color: Color(hexString: "81C8DC"),
                        width: 238,
                        height: 58,
                        fontSize: 16,
                        action: onReport
                    )

                    AppPopupActionButton(
                        title: "Block",
                        color: Color(hexString: "ACB1D7"),
                        width: 238,
                        height: 58,
                        fontSize: 16,
                        action: onBlock
                    )
                }

                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onCancel()
                }) {
                    Text("Cancel")
                        .font(.custom("Notable-Regular", size: 16))
                        .foregroundStyle(.white)
                        .frame(width: 238, height: 58)
                        .background(
                            LinearGradient(
                                colors: [Color(hexString: "FF8796"), Color(hexString: "F7B257")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 40, style: .continuous)
                                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                        )
                        .shadow(color: .white.opacity(0.25), radius: 2, x: 0, y: 2)
                }
            }
        }
    }
}

struct BanUserPopup_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    ZStack {
        Color.black
        BanUserPopup(onReport: {}, onBlock: {}, onCancel: {})
    }
}
    }
}
