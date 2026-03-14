import SwiftUI
import Combine

/**
 * [INPUT]: 依赖 SwiftUI
 * [OUTPUT]: 对外提供 BannerView
 * [POS]: UI/Components 通用轮播图组件
 * [SWIFTUI_STATE]: 使用 @Binding currentIndex 控制页码，内部 timer 驱动自动轮播
 * [SWIFTUI_PREVIEWS]: struct BannerView_Previews: PreviewProvider { static var previews: some View { 验证轮播效果
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */
struct BannerView: View {
    let images: [String]
    let height: CGFloat
    @Binding var currentIndex: Int
    
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        if images.isEmpty {
            Color.clear.frame(height: height)
        } else {
            TabView(selection: $currentIndex) {
                ForEach(0..<images.count, id: \.self) { index in
                    Image(images[index])
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .ignoresSafeArea(edges: .top)
            .onReceive(timer) { _ in
                guard images.count > 1 else { return }
                withAnimation(.easeInOut) {
                    currentIndex = (currentIndex + 1) % images.count
                }
            }
        }
    }
}

struct BannerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    BannerView(
        images: ["more_card_1", "more_card_2"],
        height: 400,
        currentIndex: .constant(0)
    )
}
    }
}
