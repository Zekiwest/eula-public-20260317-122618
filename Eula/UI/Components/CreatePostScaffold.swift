import SwiftUI

struct CreatePostScaffold<Content: View>: View {
    let backgroundImageName: String
    let onBack: () -> Void
    @ViewBuilder let content: (_ isSmallScreen: Bool) -> Content

    init(
        backgroundImageName: String = "makeup_share_bg",
        onBack: @escaping () -> Void,
        @ViewBuilder content: @escaping (_ isSmallScreen: Bool) -> Content
    ) {
        self.backgroundImageName = backgroundImageName
        self.onBack = onBack
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            let isSmallScreen = proxy.size.height <= 700

            ZStack {
                Image(backgroundImageName)
                    .resizable()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        AppBackButton(action: onBack)
                        Spacer()
                    }
                    .padding(.leading, 16)
                    .padding(.top, 10)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            content(isSmallScreen)
                        }
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                }
            }
        }
    }
}
