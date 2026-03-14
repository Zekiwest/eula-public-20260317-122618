import SwiftUI

/**
 * [INPUT]: 依赖 Assets (cat_lipstick, cat_nail, cat_foundation), CategorySubpageView
 * [OUTPUT]: 对外提供 CategoryListView
 * [POS]: UI/Home/Components 首页分类列表
 * [SWIFTUI_STATE]: 无内部状态
 * [SWIFTUI_PREVIEWS]: struct CategoryListView_Previews: PreviewProvider {
    static var previews: some View {
        Group { CategoryListView() }
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */
struct CategoryListView: View {
    private var items: [CategoryItem] {
        MockCategories.home.map { data in
            CategoryItem(icon: data.icon, name: data.name, desc: data.description, bgColor: data.bgColor)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.custom("Notable-Regular", size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 16)

            AppScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items) { item in
                        NavigationLink {
                            CategorySubpageView(title: item.name)
                                .navigationBarBackButtonHidden(true)
                        } label: {
                            CategoryCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

private struct CategoryItem: Identifiable {
    let id: String
    let icon: String
    let name: String
    let desc: String
    let bgColor: Color

    init(icon: String, name: String, desc: String, bgColor: Color) {
        self.id = name
        self.icon = icon
        self.name = name
        self.desc = desc
        self.bgColor = bgColor
    }
}

private struct CategoryCard: View {
    let item: CategoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 8) {
                Image(item.icon)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                Text(item.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
            }

            Text(item.desc)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(Color(hexString: "333333"))
                .padding(.leading, 52)
        }
        .padding(8)
        .frame(width: 160, height: 84, alignment: .topLeading)
        .background(item.bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }
}

struct CategoryListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    ZStack {
        Color.gray
        CategoryListView()
    }
}
    }
}
