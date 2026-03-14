import Foundation
import SwiftUI

enum MockSeed {
    static func stableInt(_ string: String) -> Int {
        abs(string.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) })
    }
    
    static func pick<T>(_ values: [T], seed: Int) -> T {
        values[abs(seed) % values.count]
    }
    
    static func likeCount(seed: Int) -> Int {
        let r = seed % 1000
        if r < 720 {
            return 30 + (seed % 620)
        } else if r < 960 {
            return 650 + (seed % 8200)
        } else {
            return 9000 + (seed % 68000)
        }
    }
    
    static func followerCount(seed: Int) -> Int {
        let r = seed % 1000
        if r < 700 {
            return 80 + (seed % 2400)
        } else if r < 950 {
            return 2500 + (seed % 38000)
        } else {
            return 42000 + (seed % 320000)
        }
    }
    
    static func compactCount(_ value: Int) -> String {
        if value < 1000 { return "\(value)" }
        if value < 10_000 {
            let thousands = value / 1000
            let hundreds = (value % 1000) / 100
            return hundreds == 0 ? "\(thousands)K" : "\(thousands).\(hundreds)K"
        }
        if value < 1_000_000 { return "\(value / 1000)K" }
        let millions = value / 1_000_000
        let hundredThousands = (value % 1_000_000) / 100_000
        return hundredThousands == 0 ? "\(millions)M" : "\(millions).\(hundredThousands)M"
    }
    
    static func timeHHMM(seed: Int, minuteOffset: Int = 0) -> String {
        let base = (seed % (24 * 60)) + minuteOffset
        let minutes = ((base % (24 * 60)) + (24 * 60)) % (24 * 60)
        let hh = minutes / 60
        let mm = minutes % 60
        return String(format: "%02d:%02d", hh, mm)
    }
    
    static func stableUUID(seed: Int) -> UUID {
        let v = UInt64(abs(seed)) & 0x0000_FFFF_FFFF_FFFF
        let s = String(format: "00000000-0000-0000-0000-%012llx", v)
        return UUID(uuidString: s) ?? UUID()
    }
}

enum MockUsers {
    static let marina = User(
        id: "user_marina",
        name: "Marina",
        avatarName: "more_detail_author_avatar",
        photosBackgroundName: "more_card_1"
    )
    
    static let alice = User(
        id: "user_alice",
        name: "Alice",
        avatarName: "newest_avatar_1",
        photosBackgroundName: "more_card_2"
    )
    
    static let bob = User(
        id: "user_bob",
        name: "Bob",
        avatarName: "newest_avatar_2",
        photosBackgroundName: "more_card_3"
    )
    
    static let luna = User(
        id: "user_luna",
        name: "Luna",
        avatarName: "newest_avatar_1",
        photosBackgroundName: "more_card_2"
    )
    
    static let nina = User(
        id: "user_nina",
        name: "Nina",
        avatarName: "newest_avatar_2",
        photosBackgroundName: "more_card_3"
    )
    
    static let mavis = User(
        id: "user_mavis",
        name: "Mavis",
        avatarName: "profile_header_avatar"
    )
    
    static let chloe = User(
        id: "user_chloe",
        name: "Chloe",
        avatarName: "newest_avatar_1",
        photosBackgroundName: "more_card_4"
    )
    
    static let harper = User(
        id: "user_harper",
        name: "Harper",
        avatarName: "newest_avatar_2",
        photosBackgroundName: "more_card_1"
    )
    
    static let iris = User(
        id: "user_iris",
        name: "Iris",
        avatarName: "more_detail_author_avatar",
        photosBackgroundName: "more_card_2"
    )
    
    static let jade = User(
        id: "user_jade",
        name: "Jade",
        avatarName: "profile_header_avatar",
        photosBackgroundName: "more_card_3"
    )
    
    static let keira = User(
        id: "user_keira",
        name: "Keira",
        avatarName: "newest_avatar_1",
        photosBackgroundName: "more_card_4"
    )
    
    static let naomi = User(
        id: "user_naomi",
        name: "Naomi",
        avatarName: "newest_avatar_2",
        photosBackgroundName: "more_card_1"
    )
    
    static let all: [User] = [marina, alice, bob, luna, nina, mavis, chloe, harper, iris, jade, keira, naomi]
    
    static func find(byId id: String) -> User? {
        all.first { $0.id == id }
    }
}

enum MockAssets {
    enum Avatar {
        static let marina = "more_detail_author_avatar"
        static let alice = "newest_avatar_1"
        static let bob = "newest_avatar_2"
        static let mavis = "profile_header_avatar"
        static let message = "message_avatar_1"
    }
    
    enum Card {
        static let more1 = "more_card_1"
        static let more2 = "more_card_2"
        static let more3 = "more_card_3"
        static let more4 = "more_card_4"
        static let newest1 = "newest_card_1"
        static let newest2 = "newest_card_2"
        
        static let allMore = [more1, more2, more3, more4]
        static let allNewest = [newest1, newest2]
    }
    
    enum Video {
        static let shorts = "shorts_video"
    }
}

enum MockContent {
    private static let likeColors = ["333333", "FF8796", "ACB1D7", "F7B257", "2BC7C7", "7C5CFF"]
    
    private static let titlePrefixes = ["Soft glam", "Clean girl", "Date-night", "Office-ready", "Spring", "Cherry", "Latte", "Rosy", "Peachy", "Glossy"]
    private static let titleSubjects = ["lip combo", "blush placement", "base routine", "eyeshadow blend", "liner trick", "skin prep", "brows", "highlight", "nail set"]
    private static let titleFinishes = ["step-by-step", "in 5 mins", "for photos", "for warm tones", "for cool tones", "no filter", "beginner friendly"]
    
    static func generatedTitle(seed: Int) -> String {
        let a = titlePrefixes[seed % titlePrefixes.count]
        let b = titleSubjects[(seed / 7) % titleSubjects.count]
        let c = titleFinishes[(seed / 13) % titleFinishes.count]
        return "\(a) \(b) · \(c)"
    }
    
    static let moreCards: [ContentItem] = {
        let authors = MockUsers.all
        let images = MockAssets.Card.allMore
        return (0..<10).map { index in
            let id = "more_\(index + 1)"
            let seed = MockSeed.stableInt(id)
            let author = authors[(seed + index) % authors.count]
            let imageName = images[index % images.count]
            let likeCount = MockSeed.likeCount(seed: seed)
            let likeColorHex = likeColors[seed % likeColors.count]
            let showsCardStroke = (seed % 7) == 0
            let showsAvatarStroke = (seed % 3) == 0
            return ContentItem(
                id: id,
                author: author,
                imageName: imageName,
                likeCount: likeCount,
                likeColorHex: likeColorHex,
                showsCardStroke: showsCardStroke,
                showsAvatarStroke: showsAvatarStroke
            )
        }
    }()
    
    static let videoCards: [VideoCardItem] = {
        let authors = MockUsers.all
        let covers = MockAssets.Card.allMore + MockAssets.Card.allNewest
        return (0..<6).map { index in
            let id = "video_\(index + 1)"
            let seed = MockSeed.stableInt(id)
            let author = authors[(seed + index * 3) % authors.count]
            let coverImageName = covers[(seed + index) % covers.count]
            let likeCount = MockSeed.likeCount(seed: seed + 91)
            let showsCardStroke = (seed % 5) == 0
            let showsAvatarStroke = (seed % 2) == 0
            return VideoCardItem(
                id: id,
                author: author,
                coverImageName: coverImageName,
                videoAssetName: MockAssets.Video.shorts,
                likeCount: likeCount,
                showsCardStroke: showsCardStroke,
                showsAvatarStroke: showsAvatarStroke
            )
        }
    }()
    
    static let newestCards: [NewestCardItem] = {
        let authors = MockUsers.all
        let images = MockAssets.Card.allNewest
        return (0..<8).map { index in
            let id = "newest_\(index + 1)"
            let seed = MockSeed.stableInt(id)
            let author = authors[(seed + index * 5) % authors.count]
            let imageName = images[index % images.count]
            let attention = MockSeed.compactCount(MockSeed.followerCount(seed: seed + 17))
            let title = generatedTitle(seed: seed + 101)
            return NewestCardItem(
                id: id,
                author: author,
                imageName: imageName,
                attentionCount: attention,
                title: title
            )
        }
    }()
    
    static func galleryImages(primaryImageName: String) -> [String] {
        var images = [primaryImageName]
        for img in MockAssets.Card.allMore where img != primaryImageName {
            images.append(img)
        }
        return Array(images.prefix(4))
    }
}

enum MockCategories {
    static let home: [Category] = [
        Category(
            id: "cat_lipstick",
            icon: "cat_lipstick",
            name: "Lipstick",
            description: "Color + comfort wear",
            backgroundColorHex: "FF8796"
        ),
        Category(
            id: "cat_nail",
            icon: "cat_nail",
            name: "Nail art",
            description: "Sets, tips, gel looks",
            backgroundColorHex: "ACB1D7"
        ),
        Category(
            id: "cat_foundation",
            icon: "cat_foundation",
            name: "Foundation",
            description: "Base that lasts",
            backgroundColorHex: "F7B257"
        ),
        Category(
            id: "cat_eyeshadow",
            icon: "category_eyeshadow",
            name: "Eye shadow",
            description: "Soft blends & shimmer",
            backgroundColorHex: "7C5CFF"
        )
    ]
    
    static let release: [ReleaseCategory] = [
        ReleaseCategory(
            id: "lipstick",
            rawValue: "lipstick",
            title: "lipstick",
            iconImageName: "release_category_center_lipstick",
            iconSize: CGSize(width: 32, height: 32),
            width: 68,
            textAlignment: .center
        ),
        ReleaseCategory(
            id: "eyeShadow",
            rawValue: "eyeShadow",
            title: "Eye shadow",
            iconImageName: "release_category_center_eyeshadow",
            iconSize: CGSize(width: 28, height: 28),
            width: 85,
            textAlignment: .leading
        ),
        ReleaseCategory(
            id: "foundation",
            rawValue: "foundation",
            title: "Foundation make-up",
            iconImageName: "release_category_center_foundation",
            iconSize: CGSize(width: 32, height: 32),
            width: 83,
            textAlignment: .center
        )
    ]
}

enum MockWallet {
    static let rechargeOptions: [WalletOption] = [
        WalletOption(coins: "28", price: "US$3.99", productID: "com.eula.stars.p028"),
        WalletOption(coins: "66", price: "US$8.99", productID: "com.eula.stars.p066"),
        WalletOption(coins: "150", price: "US$18.99", productID: "com.eula.stars.p150"),
        WalletOption(coins: "330", price: "US$38.99", productID: "com.eula.stars.p330"),
        WalletOption(coins: "530", price: "US$58.99", productID: "com.eula.stars.p530"),
        WalletOption(coins: "950", price: "US$98.99", productID: "com.eula.stars.p950")
    ]
}

enum MockComments {
    static let detail: [Comment] = [
        Comment(user: MockUsers.marina, content: "That base looks so smooth—what primer did you use?"),
        Comment(user: MockUsers.alice, content: "Obsessed with the blush placement. It lifts the face so nicely."),
        Comment(user: MockUsers.bob, content: "The liner is sharp! Any tips for hooded eyes?"),
        Comment(user: MockUsers.luna, content: "Please drop the lip combo (liner + gloss)."),
        Comment(user: MockUsers.chloe, content: "Soft glam done right. The shimmer is subtle but perfect."),
        Comment(user: MockUsers.harper, content: "This would be stunning for a date night look."),
        Comment(user: MockUsers.iris, content: "Your skin prep routine must be elite—no texture showing."),
        Comment(user: MockUsers.naomi, content: "What foundation shade is this? It matches so well.")
    ]
    
    static let shortsBase: [[Comment]] = [
        [
            Comment(user: MockUsers.marina, content: "The transition was so clean."),
            Comment(user: MockUsers.luna, content: "Love the color story—warm tones are perfect here."),
            Comment(user: MockUsers.nina, content: "Which palette is this? The shimmer looks buttery.")
        ],
        [
            Comment(user: MockUsers.chloe, content: "I need that brush set."),
            Comment(user: MockUsers.harper, content: "The lighting is perfect—where are you filming?"),
            Comment(user: MockUsers.jade, content: "That gloss is glassy. Brand/name?")
        ],
        [
            Comment(user: MockUsers.iris, content: "Okay this is a vibe."),
            Comment(user: MockUsers.keira, content: "Can you do a tutorial for beginners?"),
            Comment(user: MockUsers.naomi, content: "The brow shape is everything.")
        ]
    ]
}

enum MockChat {
    static let messages: [ChatMessage] = [
        ChatMessage(id: 1, isCurrentUser: true, text: "Hey! I loved your last look—especially the lip combo. What liner did you use?", time: MockSeed.timeHHMM(seed: 1123)),
        ChatMessage(id: 2, isCurrentUser: false, text: "Thank you! It was a nude-brown liner with a clear gloss on top. I’ll share the exact products tonight.", time: MockSeed.timeHHMM(seed: 1123, minuteOffset: 2)),
        ChatMessage(id: 3, isCurrentUser: false, audioURL: nil, audioDuration: 7, time: MockSeed.timeHHMM(seed: 1123, minuteOffset: 6)),
        ChatMessage(id: 4, isCurrentUser: true, audioURL: nil, audioDuration: 5, time: MockSeed.timeHHMM(seed: 1123, minuteOffset: 9))
    ]
}

enum MockShorts {
    private static let captions: [String] = [
        "Soft glam in natural light",
        "Cherry lips + dewy skin",
        "The easiest eyeliner trick",
        "No-filter base routine",
        "Latte makeup for warm tones",
        "Glowy blush placement tutorial",
        "Quick brow routine (2 minutes)",
        "Shimmer without fallout",
        "Date-night lip combo",
        "Office-ready neutral look",
        "Spring vibes, pastel eyes",
        "Clean girl makeup, but glossy",
        "Behind the scenes: filming day",
        "POV: coffee + makeup reset",
        "Nails that match the fit",
        "Cool-toned rosy glam",
        "One palette, three looks",
        "The prettiest highlight placement",
        "Skin prep you’ll feel immediately",
        "From bare face to full glam"
    ]
    
    private static let fillerContents = [
        "Love this!",
        "So pretty!",
        "Need product details pls",
        "This made my day!",
        "That blend is unreal",
        "Okay drop the shade names",
        "Your skin is glowing",
        "Tutorial when?"
    ]
    
    static func items(videoURLs: [URL]) -> [ShortsItem] {
        let authors = [MockUsers.marina, MockUsers.luna, MockUsers.nina, MockUsers.chloe, MockUsers.harper, MockUsers.naomi]
        
        return videoURLs.enumerated().map { index, url in
            let author = authors[index % authors.count]
            let seed = MockSeed.stableInt(url.lastPathComponent)
            let likeBase = 120 + (seed % 1200)
            let commentBase = 2 + (seed % 38)
            
            var comments = MockComments.shortsBase[(seed + index) % MockComments.shortsBase.count]
            if commentBase > comments.count {
                let fillers = (0..<(commentBase - comments.count)).map { i in
                    Comment(
                        user: authors[(seed + i) % authors.count],
                        content: fillerContents[(seed + i) % fillerContents.count]
                    )
                }
                comments.append(contentsOf: fillers)
            }
            
            return ShortsItem(
                id: MockSeed.stableUUID(seed: seed ^ index),
                videoURL: url,
                caption: captions[(seed + index) % captions.count],
                author: author,
                isLiked: false,
                baseLikeCount: likeBase,
                comments: comments
            )
        }
    }
}

enum MockProfile {
    static let currentUser = MockUsers.mavis
    static let followingCount = 258
    static let fansCount = 17200
}

typealias AppMockData = MockContent
