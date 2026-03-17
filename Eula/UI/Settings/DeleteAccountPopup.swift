import SwiftUI

struct DeleteAccountPopup: View {
    var onSure: () -> Void
    var onCancel: () -> Void
    
    // Figma Dimensions
    // Background dimensions: 310 x 249
    private let bgWidth: CGFloat = 310
    private let bgHeight: CGFloat = 249
    
    // Illustration offset relative to background top
    // Illustration y=0, Background y=48. Offset = -48.
    private let illustrationOffsetY: CGFloat = -48
    
    var body: some View {
        ZStack {
            // Background
            Image("popup_bg")
                .resizable(capInsets: EdgeInsets(top: 100, leading: 0, bottom: 80, trailing: 0), resizingMode: .stretch)
                .frame(width: bgWidth, height: bgHeight)
            
            VStack(spacing: 22) {
                // Text
                // Top padding calculation:
                // Illustration height (101) + gap (22) = 123 (distance from top of illustration to text)
                // Background starts at y=48.
                // Distance from background top to text = 123 - 48 = 75.
                Text("Deleting the account will clear the data.Are you sure you want to continue?")
                    .font(.system(size: 16, weight: .bold)) // Poppins Bold 16 -> SF Pro Bold 16
                    .foregroundStyle(Color(hexString: "333333"))
                    .lineSpacing(4) // approx 1.5em line height
                    .multilineTextAlignment(.leading)
                    .frame(width: 268, alignment: .leading)
                    .padding(.top, 75) // Push content down to make room for illustration
                
                // Buttons
                HStack(spacing: 10) {
                    // Sure Button (Reddish)
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onSure()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 40)
                                .fill(Color(hexString: "FF8796"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 40)
                                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                                )
                                .shadow(color: .white.opacity(0.25), radius: 4, x: 0, y: 4) // Inner shadow simulation
                            
                            Text("sure")
                                .font(.custom("Notable-Regular", size: 16))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 129, height: 49)
                    }
                    
                    // No Button (Blueish)
                    Button(action: {
                        onCancel()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 40)
                                .fill(Color(hexString: "ACB1D7"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 40)
                                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                                )
                                .shadow(color: .white.opacity(0.25), radius: 4, x: 0, y: 4) // Inner shadow simulation
                            
                            Text("no")
                                .font(.custom("Notable-Regular", size: 16))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 129, height: 49)
                    }
                }
                
                Spacer() // Push content to top
            }
        }
        .frame(width: bgWidth, height: bgHeight)
        // Illustration Overlay
        .overlay(alignment: .top) {
            Image("delete_account_illustration")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 254, height: 101)
                .offset(y: illustrationOffsetY)
        }
    }
}

struct DeleteAccountPopup_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    ZStack {
        Color.black
        DeleteAccountPopup(onSure: {}, onCancel: {})
    }
}
    }
}
