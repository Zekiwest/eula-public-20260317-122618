import SwiftUI

struct Comment: Identifiable {
    let id = UUID()
    let user: User
    let content: String
}

extension Comment {
    var name: String { user.name }
    var avatarName: String { user.avatarName }
}
