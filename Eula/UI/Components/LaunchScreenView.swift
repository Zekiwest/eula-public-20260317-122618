import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            // Design reference: 375 x 812
            let scaleX = width / 375.0
            let scaleY = height / 812.0
            let scale = max(scaleX, scaleY)
            
            ZStack {
                // 1. Background (Reusing AppBackground logic but customized for Launch Screen specific positions if needed)
                // Note: The provided design (4069_105) has very similar background blobs.
                // For 1:1 fidelity, we reconstruct it here to ensure exact matches with the specific node.
                
                Color(hexString: "10101e")
                    .ignoresSafeArea()
                
                // Background Blobs
                ZStack(alignment: .topLeading) {
                    // Ellipse 6 (Pink)
                    Ellipse()
                        .fill(Color(hexString: "ffc4cb"))
                        .frame(width: 610 * scale, height: 416 * scale)
                        .blur(radius: 200 * scale)
                        .position(
                            x: (-128 + 610/2) * scale,
                            y: (-229 + 416/2) * scale
                        )
                    
                    // Ellipse 5 (Red Deep) - Positioned differently in Launch Screen
                    // CSS: top: 102px, left: 214px relative to Ellipse 6 parent
                    // Parent (Ellipse 6 wrapper) is at top: -229, left: -128
                    // Absolute position = (-128 + 214, -229 + 102) = (86, -127) -> Same as AppBackground
                    Ellipse()
                        .fill(Color(hexString: "ff4c62"))
                        .frame(width: 235 * scale, height: 254 * scale)
                        .blur(radius: 90 * scale)
                        .position(
                            x: (86 + 235/2) * scale,
                            y: (-127 + 254/2) * scale
                        )
                    
                    // Ellipse 7 (Blue)
                    // CSS: top: 0, left: 0 relative to wrapper at top: 513, left: 203
                    // Absolute: (203, 513)
                    Ellipse()
                        .fill(Color(hexString: "81c8dc"))
                        .frame(width: 263 * scale, height: 230 * scale)
                        .blur(radius: 76 * scale)
                        .position(
                            x: (203 + 263/2) * scale,
                            y: (513 + 230/2) * scale
                        )
                    
                    // Ellipse 8 (Orange)
                    // CSS: top: -97, left: 118 relative to wrapper at top: 513, left: 203
                    // Absolute: (203+118, 513-97) = (321, 416)
                    Ellipse()
                        .fill(Color(hexString: "f7b257"))
                        .frame(width: 107 * scale, height: 156 * scale)
                        .blur(radius: 76 * scale)
                        .position(
                            x: (321 + 107/2) * scale,
                            y: (416 + 156/2) * scale
                        )
                }
                
                // 2. Decorative Image
                // CSS: bottom: -65, left: 323. Width 152.
                // In Figma coordinates (812 height): Top = 812 - 152 + 65? No, bottom is -65.
                // Let's interpret "bottom: -65". Element height 152.
                // Top = 812 - (-65) - 152 = 877 - 152 = 725? No, usually bottom means offset from bottom edge.
                // If bottom is -65, it means it's 65px below the bottom edge.
                // Wait, in CSS: .image1138 { bottom: -65px; left: 323px; }
                // This might be the decoration on the right?
                // Let's look at the screenshot. There is a decoration on the top right.
                // In the previous file (4089_898), image1138 was at bottom: -65, left: 323.
                // But in the screenshot for 4069_105, the decoration is clearly in the top right area.
                // Let's re-read CSS for 4069_105.
                // Line 28: <img ... className={styles.image1138} />
                // Line 101: .image1138 { position: absolute; bottom: -65px; left: 323px; ... }
                // This seems to position it at the bottom right.
                // BUT the screenshot shows cosmetics in the top right.
                // Wait, let's look at the node tree.
                // frame2 > instance > autoWrapper2 > image1138.
                // autoWrapper2 is at margin-top: -229, margin-left: -128.
                // So image1138 is inside autoWrapper2.
                // autoWrapper2 height is 416.
                // image1138 bottom is -65 relative to autoWrapper2.
                // autoWrapper2 top is -229. Bottom of autoWrapper2 is -229 + 416 = 187.
                // image1138 top = 187 - (-65) ? No, bottom: -65 means 65px below the bottom edge.
                // Top = 416 + 65 - 152? No.
                // Let's calculate absolute Y.
                // autoWrapper2 Top = -229. Height = 416.
                // image1138 is relative to autoWrapper2.
                // bottom: -65 means its bottom edge is at 416 + 65 = 481 (relative to autoWrapper2).
                // So image1138 Top = 481 - 152 = 329 (relative to autoWrapper2).
                // Absolute Y = -229 + 329 = 100.
                // Absolute X = -128 + 323 = 195.
                // So Position (195, 100).
                // This matches the visual "Top Right" area roughly.
                // Let's place it there.
                
                Image("LaunchDecoration")
                    .resizable()
                    .interpolation(.low)
                    .scaledToFit()
                    .frame(width: 152 * scale, height: 152 * scale)
                    .position(
                        x: (195 + 152/2) * scale,
                        y: (100 + 152/2) * scale
                    )
                
                // 3. Logo & Text Group
                // CSS: .frame1410115237 { bottom: -177px; left: 264px; ... }
                // Wait, this is also inside autoWrapper2 (Top -229, Left -128).
                // autoWrapper2 Height 416.
                // frame1410115237 bottom: -177.
                // Bottom edge relative to autoWrapper2 = 416 + 177 = 593.
                // Element Height = 131.
                // Top relative to autoWrapper2 = 593 - 131 = 462.
                // Absolute Y = -229 + 462 = 233.
                // Left: 264 relative to autoWrapper2. Absolute X = -128 + 264 = 136.
                // So the Logo is at (136, 233).
                // This seems too high? The screenshot shows Logo in the center.
                // Let's re-examine the screenshot.
                // The Logo "GLAME" is in the visual center. 812 / 2 = 406.
                // If Y is 233, it's very high.
                // Maybe autoWrapper2 is NOT the parent?
                // Line 29: <div className={styles.frame1410115237}> is inside <div className={styles.autoWrapper2}>?
                // Yes, Line 9 starts autoWrapper2. Line 39 ends it.
                // So it IS inside.
                // Let's check the CSS again.
                // .frame1410115237 { bottom: -177px; left: 264px; }
                // Maybe the parent autoWrapper2 has different dimensions?
                // width: 610px; height: 416px;
                // It seems my calculation is correct based on code, but visually it might be wrong if I misunderstood the reference frame.
                // Let's look at the screenshot again.
                // The Logo is clearly centered horizontally and slightly above center vertically.
                // X = 375/2 = 187.5. My Calc X = 136. (Off by 50px).
                // Y = ~350-400. My Calc Y = 233. (Off by 150px).
                // Let's trust the "Center" visual intent for the Logo, as CSS relative positioning with negative margins is notoriously hard to reverse-engineer perfectly without the browser layout engine.
                // However, let's try to be as close as possible.
                // frame1410115165 (The Logo Box) is 88x88.
                // Text is below it.
                // Let's use a VStack centered in the screen for safety, as Launch Screens are usually centered.
                // But wait, the user said "1:1".
                // Let's look at the `iPhoneXOrNewer` part. It's the status bar.
                // The structure seems to be a mess of absolute positioning in Figma.
                // Let's Center it. It's the most logical "Essential" choice.
                
                VStack(spacing: 12) {
                    // Logo Box
                    ZStack {
                        // Background White Rounded
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .frame(width: 88, height: 88)
                        
                        // Internal Blobs
                        // Ellipse 2 (Blue) - Top 49, Left -30 (Relative to 88x88 box)
                        Ellipse()
                            .fill(Color(hexString: "81c8dc"))
                            .frame(width: 65, height: 69)
                            .blur(radius: 18)
                            .offset(x: -30, y: 49 - 88/2 + 69/2) // Offset calculation is tricky.
                            // Let's use absolute positioning within the 88x88 frame
                            .position(x: -30 + 65/2, y: 49 + 69/2)
                        
                        // Ellipse 4 (Purple) - Top 44, Left 38
                        Ellipse()
                            .fill(Color(hexString: "acb1d7"))
                            .frame(width: 67, height: 66)
                            .blur(radius: 18)
                            .position(x: 38 + 67/2, y: 44 + 66/2)
                        
                        // Ellipse 3 (Orange) - Top -20, Left -33
                        Ellipse()
                            .fill(Color(hexString: "f7b257"))
                            .frame(width: 61, height: 61)
                            .blur(radius: 18)
                            .position(x: -33 + 61/2, y: -20 + 61/2)

                        // Ellipse 1 (Pink) - Top -29, Left 21
                        Ellipse()
                            .fill(Color(hexString: "ff8796"))
                            .frame(width: 93, height: 93)
                            .blur(radius: 18)
                            .position(x: 21 + 93/2, y: -29 + 93/2)
                        
                        // Icon
                        Image("AppLogoIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                            // CSS: top 16, left 16.
                            .position(x: 16 + 56/2, y: 16 + 56/2)
                    }
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    // Text "GLAME"
                    Text("GLAME")
                        .font(.custom("Notable-Regular", size: 24)) // Updated to explicit Notable-Regular
                        .kerning(0) // letter-spacing: 0
                        .foregroundColor(.white)
                        .textCase(.uppercase)
                }
                .scaleEffect(scale)
                .position(x: width/2, y: height/2 - 50 * scale) // Slightly above center visually
            }
        }
        .ignoresSafeArea()
    }
}

struct LaunchScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreenView()
    }
}
