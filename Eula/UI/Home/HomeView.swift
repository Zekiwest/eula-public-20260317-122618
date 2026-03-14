import SwiftUI

/**
 * [INPUT]: 依赖 Components (NewestModuleView, HomeHeaderView, CategoryListView, MoreModuleView)
 * [OUTPUT]: 对外提供 HomeView
 * [POS]: UI/Home 首页主视图，替换 ContentView 中的 Placeholder
 * [SWIFTUI_STATE]: 无内部状态，作为主 Tab 页展示
 * [SWIFTUI_PREVIEWS]: #Preview { HomeView() }
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */
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
