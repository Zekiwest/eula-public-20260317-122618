import SwiftUI

struct CategorySubpageView: View {
    let title: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarHiddenBinding) private var tabBarHiddenBinding
    @State private var showTrendTailor = false

    var body: some View {
        GeometryReader { geometry in
            AppScreen {
                VStack(spacing: 0) {
                    HStack {
                        AppBackButton(action: { dismiss() })
                        Spacer()
                        Button(action: {
                            showTrendTailor = true
                        }) {
                            TrendTailorButton()
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.leading, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity)
                    

                    AppScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Text(title)
                            //     .font(.system(size: 24, weight: .bold))
                            //     .foregroundColor(.white)
                            //     .padding(.horizontal, 16)

                            MoreCardsGridView(showsHeader: false)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showTrendTailor) {
            TrendTailorAIView()
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                tabBarHiddenBinding?.wrappedValue = true
            }
        }
        .onDisappear {
            if !showTrendTailor {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    tabBarHiddenBinding?.wrappedValue = false
                }
            }
        }
    }
}

struct CategorySubpageView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    CategorySubpageView(title: "Lipstick")
}
    }
}
