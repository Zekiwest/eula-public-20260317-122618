import SwiftUI

struct ContentItem: Identifiable, Hashable {
    let id: String
    let author: User
    let imageName: String
    let likeCount: Int
    let likeColorHex: String
    let showsCardStroke: Bool
    let showsAvatarStroke: Bool
    
    var likeColor: Color {
        Color(hexString: likeColorHex)
    }
    
    var authorId: String { author.id }
    var authorName: String { author.name }
    var authorAvatarName: String { author.avatarName }
    var baseCount: Int { likeCount }
    static let defaults: [ContentItem] = MockContent.moreCards
}

struct NewestCardItem: Identifiable, Hashable {
    let id: String
    let author: User
    let imageName: String
    let attentionCount: String
    let title: String
}

struct VideoCardItem: Identifiable, Hashable {
    let id: String
    let author: User
    let coverImageName: String
    let videoAssetName: String
    let likeCount: Int
    let showsCardStroke: Bool
    let showsAvatarStroke: Bool
    
    var authorId: String { author.id }
    var authorName: String { author.name }
    var authorAvatarName: String { author.avatarName }
    var baseCount: Int { likeCount }
    static let defaults: [VideoCardItem] = MockContent.videoCards
}

struct ShortsItem: Identifiable {
    let id: UUID
    let videoURL: URL
    let caption: String
    let author: User
    var isLiked: Bool
    let baseLikeCount: Int
    var comments: [Comment]
    
    var username: String { author.name }
    var avatarName: String { author.avatarName }
    var profileUser: BanUserTarget { author.toBanUserTarget() }
    var profilePhotosBackgroundName: String { author.photosBackgroundName ?? "more_card_1" }
}
