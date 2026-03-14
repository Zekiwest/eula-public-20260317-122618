import SwiftUI

struct ChatMessage: Identifiable {
    let id: Int
    let isCurrentUser: Bool
    let type: MessageType
    let text: String
    let time: String
    let audioURL: URL?
    let audioDuration: TimeInterval?
    let isTyping: Bool
    
    enum MessageType {
        case text
        case audio
    }

    init(id: Int, isCurrentUser: Bool, text: String, time: String, isTyping: Bool = false) {
        self.id = id
        self.isCurrentUser = isCurrentUser
        self.type = .text
        self.text = text
        self.time = time
        self.audioURL = nil
        self.audioDuration = nil
        self.isTyping = isTyping
    }

    init(id: Int, isCurrentUser: Bool, audioURL: URL?, audioDuration: TimeInterval, time: String) {
        self.id = id
        self.isCurrentUser = isCurrentUser
        self.type = .audio
        self.text = ""
        self.time = time
        self.audioURL = audioURL
        self.audioDuration = audioDuration
        self.isTyping = false
    }

    var audioDurationText: String {
        let seconds = Int(ceil(audioDuration ?? 0))
        return "\(max(1, seconds))s"
    }
}
