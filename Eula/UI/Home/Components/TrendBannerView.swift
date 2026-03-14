import SwiftUI

/**
 * [INPUT]: 依赖 Assets (trend_tailor_icon)
 * [OUTPUT]: 对外提供 NewestModuleView, TrendTailorButton
 * [POS]: UI/Home/Components 首页 "newest" 模块头部
 * [SWIFTUI_STATE]: 无内部状态
 * [SWIFTUI_PREVIEWS]: struct TrendBannerView_Previews: PreviewProvider {
    static var previews: some View {
        Group { NewestModuleView() }
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */
struct NewestModuleView: View {
    var body: some View {
        HStack {
            Text("newest")
                .font(.custom("Notable-Regular", size: 16)) // Notable-Regular (Kept as per user request)
                .foregroundColor(.white)
                .textCase(.lowercase) // Ensure visual consistency
            
            Spacer()
            
            NavigationLink(destination: TrendTailorAIView()) {
                TrendTailorButton()
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 16)
        .frame(height: 40)
    }
}

struct TrendTailorButton: View {
    var body: some View {
        HStack(spacing: 0) {
            Image("trend_tailor_icon")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .padding(.leading, 6)

            Text("TrendTailor AI")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 76, alignment: .leading)
                .padding(.leading, 2)

            Spacer()
        }
        .frame(width: 126, height: 40)
        .background(Color(hexString: "10101E"))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 100,
                bottomLeadingRadius: 100,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
        )
    }
}

struct TrendBannerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    ZStack {
        Color.gray
        NewestModuleView()
    }
}
    }
}
