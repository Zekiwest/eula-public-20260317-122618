import SwiftUI

struct User: Identifiable, Hashable {
    let id: String
    let name: String
    let avatarName: String
    var photosBackgroundName: String? = nil
}

extension User {
    func toBanUserTarget() -> BanUserTarget {
        BanUserTarget(id: id, name: name, avatarName: avatarName)
    }
}
