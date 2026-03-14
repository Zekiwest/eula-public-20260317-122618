import SwiftUI

struct CollectsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarHiddenBinding) private var tabBarHiddenBinding

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / 375, proxy.size.height / 812)

            AppScreen {
                ZStack(alignment: .top) {
                    AppScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            MoreCardsGridView(showsHeader: false)
                        }
                        .padding(.top, 66)
                        .padding(.bottom, 24)
                    }

                    topBar(scale: scale)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                tabBarHiddenBinding?.wrappedValue = true
            }
        }
        .onDisappear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                tabBarHiddenBinding?.wrappedValue = false
            }
        }
    }

    private func topBar(scale: CGFloat) -> some View {
        HStack(spacing: 20 * scale) {
            AppBackButton(action: { dismiss() })

            Text("Collects")
                .font(.custom("Notable-Regular", size: 20 * scale))
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.leading, 16)
        .padding(.top, 10)
        .padding(.trailing, 16)
    }
}

struct CollectsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    NavigationStack {
        CollectsView()
    }
}
    }
}
