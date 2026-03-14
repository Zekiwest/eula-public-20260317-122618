import SwiftUI

/**
 * [INPUT]: 依赖 SwiftUI
 * [OUTPUT]: 对外提供 CustomPageControl
 * [POS]: UI/Components 通用分页指示器
 * [SWIFTUI_STATE]: 使用 @Binding currentIndex 驱动胶囊动画
 * [SWIFTUI_PREVIEWS]: struct CustomPageControl_Previews: PreviewProvider { static var previews: some View { 验证指示器样式
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */
struct CustomPageControl: View {
    let numberOfPages: Int
    @Binding var currentIndex: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                    .frame(width: index == currentIndex ? 16 : 6, height: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct CustomPageControl_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    ZStack {
        Color.black
        CustomPageControl(numberOfPages: 4, currentIndex: .constant(1))
    }
}
    }
}
