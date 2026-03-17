import SwiftUI

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
