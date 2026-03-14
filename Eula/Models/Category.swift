import SwiftUI

struct Category: Identifiable {
    let id: String
    let icon: String
    let name: String
    let description: String
    let backgroundColorHex: String
    
    var bgColor: Color {
        Color(hexString: backgroundColorHex)
    }
}

struct ReleaseCategory: Identifiable {
    let id: String
    let rawValue: String
    let title: String
    let iconImageName: String
    let iconSize: CGSize
    let width: CGFloat
    let textAlignment: TextAlignment
}
