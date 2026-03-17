import SwiftUI

struct HomeView: View {
    @Environment(\.tabBarHiddenBinding) private var tabBarHiddenBinding

    var body: some View {
        NavigationStack {
            AppScreen {
                ZStack {
                    AppScrollView {
                        VStack(spacing: 0) {
                            Spacer().frame(height: 20)

                            VStack(spacing: 16) {
                                VStack(spacing: 16) {
                                    NewestModuleView()
                                    HomeHeaderView()
                                }

                                CategoryListView()
                                MoreModuleView()
                            }

                            Spacer().frame(height: 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                tabBarHiddenBinding?.wrappedValue = false
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
