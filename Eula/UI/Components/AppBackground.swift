/**
 * [INPUT]: 依赖 Assets.xcassets 中的 EULA_BackIcon
 * [OUTPUT]: 对外提供 AppBackground, AppScreen, AppScrollView, AppBackButton
 * [POS]: UI/Components 的核心背景组件，被全局使用
 * [SWIFTUI_STATE]: 无内部状态，纯静态展示
 * [SWIFTUI_PREVIEWS]: struct AppBackground_Previews: PreviewProvider { static var previews: some View { 验证 iPhone 尺寸适配
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */

import SwiftUI

struct AppBackground: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            // Design reference: 375 x 812
            let scaleX = width / 375.0
            let scaleY = height / 812.0
            let scale = max(scaleX, scaleY) // Use 'fill' strategy
            #if targetEnvironment(simulator)
            let blurQualityScale: CGFloat = 0.45
            #else
            let blurQualityScale: CGFloat = 1
            #endif
            
            ZStack(alignment: .topLeading) {
                // 1. Base Background
                Color(hexString: "10101e")
                    .ignoresSafeArea()
                
                // 2. Top Left Group (Pink/Red Blobs)
                // Ellipse 6 (Pink)
                Ellipse()
                    .fill(Color(hexString: "ffc4cb"))
                    .frame(width: 610 * scale, height: 416 * scale)
                    .blur(radius: 200 * scale * blurQualityScale)
                    .position(
                        x: (-128 + 610/2) * scale,
                        y: (-229 + 416/2) * scale
                    )
                
                // Ellipse 5 (Red Deep) - Inside Ellipse 6 logic
                Ellipse()
                    .fill(Color(hexString: "ff4c62"))
                    .frame(width: 235 * scale, height: 254 * scale)
                    .blur(radius: 90 * scale * blurQualityScale)
                    .position(
                        x: (86 + 235/2) * scale,
                        y: (-127 + 254/2) * scale
                    )
                
                // 3. Bottom Right Group (Blue/Orange)
                // Ellipse 7 (Blue)
                Ellipse()
                    .fill(Color(hexString: "81c8dc"))
                    .frame(width: 263 * scale, height: 230 * scale)
                    .blur(radius: 76 * scale * blurQualityScale)
                    .position(
                        x: (203 + 263/2) * scale,
                        y: (513 + 230/2) * scale
                    )
                
                // Ellipse 8 (Orange)
                Ellipse()
                    .fill(Color(hexString: "f7b257"))
                    .frame(width: 107 * scale, height: 156 * scale)
                    .blur(radius: 76 * scale * blurQualityScale)
                    .position(
                        x: (321 + 107/2) * scale,
                        y: (416 + 156/2) * scale
                    )
            }
            .frame(width: width, height: height)
            .clipped() // Ensure content doesn't bleed out
            .drawingGroup()
        }
        .ignoresSafeArea()
    }
}

struct AppScreen<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppBackground()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.clear)
    }
}

struct AppScrollView<Content: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    let content: Content

    init(_ axes: Axis.Set = .vertical, showsIndicators: Bool = true, @ViewBuilder content: () -> Content) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.content = content()
    }

    var body: some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            content
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
}

struct AppBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image("EULA_BackIcon")
                .resizable()
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
    }
}

struct AppNavIconButton: View {
    let imageName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
    }
}

struct AppTopBar: View {
    let topInset: CGFloat
    var leadingIconName: String?
    var trailingIconName: String?
    var onLeadingTap: (() -> Void)?
    var onTrailingTap: (() -> Void)?

    var body: some View {
        HStack {
            if let leadingIconName, let onLeadingTap {
                AppNavIconButton(imageName: leadingIconName, action: onLeadingTap)
            } else {
                Color.clear
                    .frame(width: 40, height: 40)
            }

            Spacer()

            if let trailingIconName, let onTrailingTap {
                AppNavIconButton(imageName: trailingIconName, action: onTrailingTap)
            } else {
                Color.clear
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.top, topInset + 10)
        .padding(.horizontal, 16)
    }
}

struct AppBackground_Previews: PreviewProvider {
    static var previews: some View {
        AppBackground()
    }
}
