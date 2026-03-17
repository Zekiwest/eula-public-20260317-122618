import SwiftUI

struct MasonryFeedView: View {
    var body: some View {
        let items = Array(MockContent.moreCards.prefix(8))
        let leftItems = items.enumerated().compactMap { $0.offset.isMultiple(of: 2) ? $0.element : nil }
        let rightItems = items.enumerated().compactMap { !$0.offset.isMultiple(of: 2) ? $0.element : nil }
        HStack(alignment: .top, spacing: 16) {
            LazyVStack(spacing: 16) {
                ForEach(leftItems) { item in
                    FeedCard(item: item)
                }
            }
            
            LazyVStack(spacing: 16) {
                ForEach(rightItems) { item in
                    FeedCard(item: item)
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

private struct FeedCard: View {
    let item: ContentItem
    
    var body: some View {
        let seed = MockSeed.stableInt(item.id)
        let imageHeight: CGFloat = (seed % 3) == 0 ? 260 : ((seed % 3) == 1 ? 210 : 180)
        VStack(alignment: .leading, spacing: 8) {
            Image(item.imageName)
                .resizable()
                .scaledToFill()
                .frame(height: imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Text(MockContent.generatedTitle(seed: seed))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
            
            HStack {
                HStack(spacing: 6) {
                    Image(item.author.avatarName)
                        .resizable()
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                    
                    Text(item.author.name)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image("icon_heart_fill")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .frame(width: 12, height: 12)
                    
                    Text("\(item.likeCount)")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.3))
                .clipShape(Capsule())
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct MasonryFeedView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    ZStack {
        Color.black
        MasonryFeedView()
    }
}
    }
}
