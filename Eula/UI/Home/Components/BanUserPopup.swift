import SwiftUI

/**
 * [INPUT]: 依赖 Assets (TermsofUse_bg)
 * [OUTPUT]: 对外提供 BanUserPopup
 * [POS]: UI/Home/Components/BanUserPopup.swift
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */
struct BanUserPopup: View {
    var onReport: () -> Void
    var onBlock: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Image("TermsofUse_bg")
                .resizable(capInsets: EdgeInsets(top: 180, leading: 0, bottom: 150, trailing: 0), resizingMode: .stretch)
                .frame(width: 343, height: 302)
            
            VStack(spacing: 24) {
                // Report & Block Buttons Group
                VStack(spacing: 16) {
                    // Report Button
                    PopupButton(
                        title: "Report",
                        color: Color(hexString: "81C8DC"),
                        action: onReport
                    )
                    
                    // Block Button
                    PopupButton(
                        title: "Block",
                        color: Color(hexString: "ACB1D7"),
                        action: onBlock
                    )
                }
                
                // Cancel Button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onCancel()
                }) {
                    Text("Cancel")
                        .font(.custom("Notable-Regular", size: 16))
                        .foregroundColor(.white)
                        .frame(width: 238, height: 58)
                        .background(
                            LinearGradient(
                                colors: [Color(hexString: "FF8796"), Color(hexString: "F7B257")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                        )
                        .shadow(color: .white.opacity(0.25), radius: 2, x: 0, y: 2) // Simple shadow simulation
                }
            }
            // Adjust position based on Figma (x: 52, y: 44 relative to 343x302 container)
            // Center of container is 343/2 = 171.5. 52 + 238/2 = 52 + 119 = 171.
            // So it is horizontally centered.
            // Vertical: y=44. Container 302. Center 151.
            // Content height: 58 + 16 + 58 + 24 + 58 = 214.
            // 44 + 214/2 = 44 + 107 = 151.
            // So it is vertically centered too.
        }
    }
}

private struct PopupButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text(title)
                .font(.custom("Notable-Regular", size: 16))
                .foregroundColor(.white)
                .frame(width: 238, height: 58)
                .background(color)
                .cornerRadius(40)
                .overlay(
                    RoundedRectangle(cornerRadius: 40)
                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                )
                .shadow(color: .white.opacity(0.25), radius: 2, x: 0, y: 2)
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
