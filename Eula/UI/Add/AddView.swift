import SwiftUI

struct AddView: View {
    var onClose: () -> Void
    var onMakeupShare: (() -> Void)?
    var onReleaseVideo: (() -> Void)?
    
    // Base dimensions from Figma (iPhone X)
    private let baseWidth: CGFloat = 375
    private let baseHeight: CGFloat = 812
    
    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / baseWidth, geometry.size.height / baseHeight)
            
            ZStack {
                // Background Blur (Figma: fill 000000 50%, backdrop blur 8px)
                Color.black.opacity(0.5)
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture {
                        onClose()
                    }
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Cards Row
                    HStack(spacing: 48 * scale) {
                        // Left Card
                        makeCard(
                            title: "Makeup Share",
                            description: "You can post your own makeup videos",
                            imageName: "add_makeup_share",
                            backgroundColor: Color(red: 255/255, green: 135/255, blue: 150/255, opacity: 0.9),
                            scale: scale
                        )
                        .onTapGesture {
                            onMakeupShare?()
                        }
                        
                        // Right Card
                        makeCard(
                            title: "Release Video",
                            description: "You can post your own makeup videos",
                            imageName: "add_release_video",
                            backgroundColor: Color(red: 172/255, green: 177/255, blue: 215/255, opacity: 0.9),
                            scale: scale
                        )
                        .onTapGesture {
                            onReleaseVideo?()
                        }
                    }
                    
                    Spacer()
                        .frame(height: 35 * scale)
                    
                    // Close Button
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24 * scale, height: 24 * scale)
                            .foregroundStyle(.white)
                            .contentShape(Rectangle()) // Improve tap area
                            .frame(width: 44 * scale, height: 44 * scale) // Min tap area
                    }
                    
                    Spacer()
                        .frame(height: 61 * scale)
                }
            }
        }
    }
    
    private func makeCard(title: String, description: String, imageName: String, backgroundColor: Color, scale: CGFloat) -> some View {
        VStack(spacing: 10 * scale) {
            VStack(spacing: 16 * scale) {
                Text(title)
                    .font(.custom("Notable-Regular", size: 10 * scale))
                    .foregroundStyle(.white)
                
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 99 * scale, height: 76 * scale)
                    .background(Color.white.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 16 * scale))
            }
            
            Text(description)
                .font(.system(size: 12 * scale, weight: .regular))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 12 * scale)
        .padding(.horizontal, 10 * scale)
        .frame(width: 129 * scale, height: 192 * scale)
        // Card Background: Color + Blur
        // Note: The Figma design has a solid(ish) color with blur behind it.
        // If we just use the color, we don't see what's behind the card blurred.
        // We need .background(.ultraThinMaterial) to blur the content BEHIND the card,
        // and then overlay the color with opacity.
        .background {
            ZStack {
                // The blur effect
                Rectangle()
                    .fill(.ultraThinMaterial)
                // The color tint
                Rectangle()
                    .fill(backgroundColor)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20 * scale))
    }
}

struct AddView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    AddView(onClose: {})
}
    }
}
