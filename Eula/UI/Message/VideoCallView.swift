import SwiftUI

struct VideoCallView: View {
    let name: String
    let avatarName: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / 375, proxy.size.height / 812)
            
            ZStack {
                // Background
                ZStack {
                    // Base background layer
                    Image(avatarName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .blur(radius: 20)
                        .overlay(Color.black.opacity(0.2))
                    
                    // Gradient overlay from design
                    LinearGradient(
                        stops: [
                            .init(color: Color(hexString: "FF8796"), location: 0.0),
                            .init(color: Color.white.opacity(0), location: 0.9984)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                }
                .ignoresSafeArea()
                
                // Content
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 180 * scale)
                    
                    // Profile Circle
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2)) // #ffffff33
                            .frame(width: 142 * scale, height: 142 * scale)
                        
                        Image(avatarName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 116 * scale, height: 116 * scale)
                            .clipShape(Circle())
                    }
                    
                    VStack(spacing: 8 * scale) {
                        Text(name)
                            .font(.custom("Notable-Regular", size: 20 * scale))
                            .foregroundStyle(.white)
                            .tracking(0)
                        
                        Text("Calling...")
                            .font(.system(size: 16 * scale, weight: .medium)) // Poppins 500 -> System Medium
                            .foregroundStyle(.white)
                            .tracking(0)
                    }
                    .padding(.top, 16 * scale)
                    
                    Spacer()
                    
                    // Hang up button
                    Button {
                        dismiss()
                    } label: {
                        Image("video_call_hangup")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 96 * scale, height: 54 * scale)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 80 * scale)
                }
            }
        }
    }
}

struct VideoCallView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    VideoCallView(name: "Mavis", avatarName: "message_avatar_1")
}
    }
}
