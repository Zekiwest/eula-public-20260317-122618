import SwiftUI

struct ReleaseVideoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @State private var selectedVideoURL: URL? = nil

    var body: some View {
        AppScreen {
            CreatePostScaffold(onBack: { dismiss() }) { isSmallScreen in
                TrendTailorChatArea(
                    text: $text,
                    placeholder: "Details: Share your thoughts on this makeup look! Add color to the charm of the video with your words."
                )
                .frame(height: 300)
                .padding(.horizontal, 20)
                .padding(.top, 26)

                TrendTailorVideoUploadSection(
                    selectedVideoURL: $selectedVideoURL,
                    uploadIconName: "release_video_upload",
                    usesFullImage: true,
                    placeholderImageName: "release_video_upload",
                    showsDeleteButton: true
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)

                ReleaseVideoCategorySection()
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                MakeupSharePostButton {
                    dismiss()
                }
                .padding(.top, 40)
                .padding(.bottom, isSmallScreen ? 24 : 58)
            }
        }
        .navigationBarHidden(true)
    }
}

struct ReleaseVideoCategorySection: View {
    private enum Category: String {
        case lipstick
        case eyeShadow
        case foundation
    }

    private struct CategoryItem: Identifiable {
        let id = UUID()
        let category: Category
        let title: String
        let iconImageName: String
        let iconSize: CGSize
        let width: CGFloat
        let textAlignment: TextAlignment
    }

    private var items: [CategoryItem] {
        MockCategories.release.compactMap { data in
            guard let category = Category(rawValue: data.rawValue) else {
                return nil
            }
            return CategoryItem(
                category: category,
                title: data.title,
                iconImageName: data.iconImageName,
                iconSize: data.iconSize,
                width: data.width,
                textAlignment: data.textAlignment
            )
        }
    }

    @State private var selectedCategory: Category = .lipstick

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Category:")
                .font(.custom("Notable-Regular", size: 16))
                .foregroundStyle(.white)

            HStack(alignment: .top, spacing: 48) {
                ForEach(items) { item in
                    ReleaseVideoCategoryOption(
                        title: item.title,
                        iconImageName: item.iconImageName,
                        iconSize: item.iconSize,
                        isSelected: selectedCategory == item.category,
                        width: item.width,
                        textAlignment: item.textAlignment
                    ) {
                        selectedCategory = item.category
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ReleaseVideoCategoryOption: View {
    let title: String
    let iconImageName: String
    let iconSize: CGSize
    let isSelected: Bool
    let width: CGFloat
    let textAlignment: TextAlignment
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                ReleaseVideoCategoryTile(iconImageName: iconImageName, iconSize: iconSize, isSelected: isSelected)

                Text(title)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(textAlignment)
                    .frame(width: width)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ReleaseVideoCategoryTile: View {
    let iconImageName: String
    let iconSize: CGSize
    let isSelected: Bool

    private let tileSize = CGSize(width: 68, height: 40)

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        let strokeColor = isSelected ? Color(hexString: "FF8796") : .white

        ZStack {
            shape
                .fill(.white.opacity(0.2))
                .background(.ultraThinMaterial)
                .clipShape(shape)
                .overlay {
                    shape
                        .stroke(strokeColor, lineWidth: 1)
                }

            Image(iconImageName)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize.width, height: iconSize.height)
        }
        .frame(width: tileSize.width, height: tileSize.height)
    }
}
