import SwiftUI

struct TrendTailorGetButton: View {
    let isCompact: Bool
    let costCoins: Int
    var action: () -> Void

    init(isCompact: Bool = false, costCoins: Int = 10, action: @escaping () -> Void) {
        self.isCompact = isCompact
        self.costCoins = costCoins
        self.action = action
    }

    var body: some View {
        let iconSize: CGFloat = isCompact ? 28 : 32
        let fontSize: CGFloat = isCompact ? 14 : 16
        let contentSpacing: CGFloat = isCompact ? 10 : 12
        let leftSpacing: CGFloat = isCompact ? 6 : 8
        let verticalPadding: CGFloat = isCompact ? 5 : 6
        let buttonWidth: CGFloat = isCompact ? 210 : 238
        let buttonHeight: CGFloat = isCompact ? 48 : 56
        let cornerRadius: CGFloat = isCompact ? 32 : 40

        Button(action: action) {
            HStack(spacing: contentSpacing) {
                // Left Part: Icon + GET
                HStack(spacing: leftSpacing) {
                    Image("icon_get")
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                    
                    Text("GET")
                        .font(.custom("Notable-Regular", size: fontSize))
                        .foregroundStyle(.white)
                }
                
                // Right Part: -300
                Text("-\(costCoins)")
                    .font(.custom("Notable-Regular", size: fontSize))
                    .foregroundStyle(Color(red: 1, green: 1, blue: 0)) // #FFFF00
            }
            .padding(.vertical, verticalPadding)
            .frame(width: buttonWidth, height: buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 255/255, green: 135/255, blue: 150/255), location: 0.32),
                                .init(color: Color(red: 247/255, green: 178/255, blue: 87/255), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    // Inner Shadow Simulation
                    .overlay(
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
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 2)
            )
            // Shadow for depth (optional, based on design usually having some drop shadow, but not specified in prompt. Figma had inner shadow. I added inner shadow simulation above)
        }
    }
}

struct TrendTailorGetButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    ZStack {
        Color.black
        TrendTailorGetButton(action: {})
    }
}
    }
}
