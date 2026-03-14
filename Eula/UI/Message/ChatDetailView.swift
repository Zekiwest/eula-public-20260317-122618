import SwiftUI
import AVFoundation
import Combine

struct ChatDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarHiddenBinding) private var tabBarHiddenBinding
    @EnvironmentObject private var profileStatsStore: ProfileStatsStore
    
    let name: String
    let avatarName: String
    let personaKey: String
    let userId: String
    
    @State private var inputText: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var inputMode: ChatInputMode = .text
    @State private var showMicPermissionAlert = false
    @State private var showVideoCall = false
    @StateObject private var voiceIO = VoiceIO()
    @State private var isSendingToAI = false
    @State private var sendTask: Task<Void, Never>?
    @State private var lastErrorText: String?

    enum ChatInputMode {
        case text
        case voice
    }
    
    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / 375, proxy.size.height / 812)
            
            AppScreen {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        AppBackButton {
                            dismiss()
                        }

                        Text(name.uppercased())
                            .font(.system(size: 20 * scale, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.leading, 20 * scale)

                        Button {
                            if profileStatsStore.isMutualFollowing(userId) {
                                showVideoCall = true
                            } else {
                                ToastManager.shared.show("需要互相关注才能视频通话")
                            }
                        } label: {
                            Image(systemName: "video.fill")
                                .font(.system(size: 24 * scale, weight: .regular))
                                .foregroundStyle(.white)
                                .frame(width: 24 * scale, height: 24 * scale)
                        }
                        .padding(.leading, 20 * scale)
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                        } label: {
                            Image("more_detail_more")
                                .renderingMode(.original)
                        }
                        .frame(width: 40 * scale, height: 40 * scale)
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 16)

                    ZStack(alignment: .bottom) {
                        TopRoundedRectangle(radius: 20 * scale)
                            .fill(Color(hexString: "131220"))
                            .ignoresSafeArea(edges: .bottom)

                        VStack(spacing: 0) {
                            Text("Now")
                                .font(.system(size: 12 * scale, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.top, 20 * scale)

                            ScrollViewReader { scrollProxy in
                                ScrollView {
                                    LazyVStack(spacing: 18 * scale) {
                                        if let lastErrorText {
                                            Text(lastErrorText)
                                                .font(.system(size: 12 * scale, weight: .medium))
                                                .foregroundStyle(.white.opacity(0.75))
                                                .padding(.vertical, 6 * scale)
                                                .frame(maxWidth: .infinity, alignment: .center)
                                        }

                                        ForEach(messages) { message in
                                            ChatBubbleRow(
                                                message: message,
                                                scale: scale,
                                                currentAvatarName: "message_avatar_1",
                                                otherAvatarName: avatarName,
                                                playingAudioURL: voiceIO.playingURL,
                                                onAudioTap: { tapped in
                                                    guard let url = tapped.audioURL else { return }
                                                    if voiceIO.playingURL == url {
                                                        voiceIO.stopPlayback()
                                                    } else {
                                                        voiceIO.play(url: url)
                                                    }
                                                }
                                            )
                                            .id(message.id)
                                        }
                                    }
                                    .padding(.top, 18 * scale)
                                    .padding(.bottom, 140 * scale)
                                }
                                .scrollIndicators(.hidden)
                                .onChange(of: messages.count, perform: { _ in
                                    guard let lastID = messages.last?.id else { return }
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        scrollProxy.scrollTo(lastID, anchor: .bottom)
                                    }
                                })
                                .onAppear {
                                    guard let lastID = messages.last?.id else { return }
                                    scrollProxy.scrollTo(lastID, anchor: .bottom)
                                }
                            }
                        }
                        .padding(.horizontal, 16 * scale)

                        ChatInputBar(
                            text: $inputText,
                            mode: $inputMode,
                            voiceIO: voiceIO,
                            scale: scale,
                            onMicTap: switchToVoiceMode,
                            onKeyboardTap: switchToTextMode,
                            onSendTap: sendFromCurrentMode
                        )
                        .padding(.bottom, 0)
                        .ignoresSafeArea(.container, edges: .bottom)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 10 * scale)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Microphone Access Needed", isPresented: $showMicPermissionAlert) {
            Button("OK") { }
        } message: {
            Text("Please allow microphone access in Settings to record voice messages.")
        }
        .fullScreenCover(isPresented: $showVideoCall) {
            VideoCallView(name: name, avatarName: avatarName)
        }
        .toast()
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                tabBarHiddenBinding?.wrappedValue = true
            }
        }
        .onDisappear {
            sendTask?.cancel()
            voiceIO.stopPlayback()
            voiceIO.cancelRecording()
            if !showVideoCall {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    tabBarHiddenBinding?.wrappedValue = false
                }
            }
        }
    }

    private func sendFromCurrentMode() {
        if isSendingToAI {
            return
        }
        switch inputMode {
        case .text:
            let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            lastErrorText = nil
            messages.append(ChatMessage(id: nextMessageID, isCurrentUser: true, text: trimmed, time: currentTimeString()))
            inputText = ""
            sendToAI()
        case .voice:
            guard let result = voiceIO.stopRecording() else { return }
            guard result.duration >= 0.25 else {
                inputMode = .text
                return
            }
            messages.append(
                ChatMessage(
                    id: nextMessageID,
                    isCurrentUser: true,
                    audioURL: result.url,
                    audioDuration: result.duration,
                    time: currentTimeString()
                )
            )
            inputMode = .text
        }
    }

    private func sendToAI() {
        sendTask?.cancel()

        let placeholderID = nextMessageID
        messages.append(ChatMessage(id: placeholderID, isCurrentUser: false, text: "", time: currentTimeString(), isTyping: true))
        isSendingToAI = true

        sendTask = Task {
            do {
                let reply = try await ChatBackend.shared.send(
                    conversationID: name,
                    personaKey: personaKey,
                    messages: makeAIHistory(maxCount: 20, excludingMessageID: placeholderID)
                )

                if Task.isCancelled { return }
                await MainActor.run {
                    isSendingToAI = false
                    let text = reply.reply.trimmingCharacters(in: .whitespacesAndNewlines)
                    replaceTextMessage(id: placeholderID, newText: text.isEmpty ? "(empty response)" : text)
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    isSendingToAI = false
                    let fallback = "（请求失败：\(error.localizedDescription)）"
                    lastErrorText = fallback
                    replaceTextMessage(id: placeholderID, newText: fallback)
                }
            }
        }
    }

    private func replaceTextMessage(id: Int, newText: String) {
        guard let idx = messages.firstIndex(where: { $0.id == id }) else { return }
        let old = messages[idx]
        messages[idx] = ChatMessage(id: old.id, isCurrentUser: old.isCurrentUser, text: newText, time: old.time)
    }

    private func makeAIHistory(maxCount: Int, excludingMessageID: Int?) -> [ChatHistoryMessage] {
        let textMessages = messages
            .filter { $0.type == .text }
            .filter { msg in
                guard let excludingMessageID else { return true }
                return msg.id != excludingMessageID
            }
            .filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        let suffix = max(0, min(maxCount, textMessages.count))
        return textMessages.suffix(suffix).map { msg in
            ChatHistoryMessage(
                role: msg.isCurrentUser ? .user : .assistant,
                content: msg.text
            )
        }
    }

    private func switchToVoiceMode() {
        if voiceIO.hasRecordPermission {
            do {
                try voiceIO.startRecording()
                inputMode = .voice
            } catch {
                inputMode = .text
            }
            return
        }

        voiceIO.requestRecordPermission { granted in
            if granted {
                do {
                    try voiceIO.startRecording()
                    inputMode = .voice
                } catch {
                    inputMode = .text
                }
            } else {
                showMicPermissionAlert = true
                inputMode = .text
            }
        }
    }

    private func switchToTextMode() {
        voiceIO.cancelRecording()
        inputMode = .text
    }

    private var nextMessageID: Int {
        (messages.map { $0.id }.max() ?? 0) + 1
    }

    private func currentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }

}

struct ChatBubbleRow: View {
    let message: ChatMessage
    let scale: CGFloat
    let currentAvatarName: String
    let otherAvatarName: String
    let playingAudioURL: URL?
    let onAudioTap: (ChatMessage) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 10 * scale) {
            if message.isCurrentUser {
                Spacer()

                VStack(alignment: .trailing, spacing: 6 * scale) {
                    ChatBubble(message: message, scale: scale, playingAudioURL: playingAudioURL)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard message.type == .audio else { return }
                            onAudioTap(message)
                        }
                    Text(message.time)
                        .font(.system(size: 10 * scale, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Image(currentAvatarName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36 * scale, height: 36 * scale)
                    .clipShape(Circle())
            } else {
                Image(otherAvatarName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36 * scale, height: 36 * scale)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6 * scale) {
                    ChatBubble(message: message, scale: scale, playingAudioURL: playingAudioURL)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard message.type == .audio else { return }
                            onAudioTap(message)
                        }
                    Text(message.time)
                        .font(.system(size: 10 * scale, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()
            }
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    let scale: CGFloat
    let playingAudioURL: URL?
    
    var body: some View {
        HStack(spacing: 8 * scale) {
            if message.isTyping {
                TypingIndicator(scale: scale)
            } else if message.type == .audio {
                let isPlaying = (message.audioURL != nil && message.audioURL == playingAudioURL)
                if message.isCurrentUser {
                    Text(message.audioDurationText)
                        .font(.system(size: 14 * scale, weight: .medium))
                        .foregroundStyle(.black)
                    VoicePlaybackIndicator(isPlaying: isPlaying, tint: .black, scale: scale)
                } else {
                    VoicePlaybackIndicator(isPlaying: isPlaying, tint: .white, scale: scale)
                    Text(message.audioDurationText)
                        .font(.system(size: 14 * scale, weight: .medium))
                        .foregroundStyle(.white)
                }
            } else {
                Text(message.text)
                    .font(.system(size: 14 * scale, weight: .medium))
                    .foregroundStyle(message.isCurrentUser ? .black : .white)
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, 12 * scale)
        .padding(.vertical, 10 * scale)
        .background(
            message.isCurrentUser 
            ? Color.white 
            : Color(hexString: "ACB1D7")
        )
        .clipShape(
            ChatBubbleShape(
                topLeft: message.isCurrentUser ? 10 * scale : 0,
                topRight: message.isCurrentUser ? 0 : 10 * scale,
                bottomLeft: 10 * scale,
                bottomRight: 10 * scale
            )
        )
        .frame(maxWidth: 260 * scale, alignment: message.isCurrentUser ? .trailing : .leading)
    }
}

struct TypingIndicator: View {
    let scale: CGFloat
    
    var body: some View {
        HStack(spacing: 4 * scale) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 8 * scale, height: 8 * scale)
                    .scaleEffect(animationScale(for: index))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                animPhase = 1
            }
        }
    }
    
    @State private var animPhase: CGFloat = 0
    
    private func animationScale(for index: Int) -> CGFloat {
        let delay = CGFloat(index) * 0.2
        let phase = (animPhase + delay).truncatingRemainder(dividingBy: 1.0)
        return 0.6 + 0.4 * sin(phase * .pi * 2)
    }
}

struct ChatBubbleShape: Shape {
    let topLeft: CGFloat
    let topRight: CGFloat
    let bottomLeft: CGFloat
    let bottomRight: CGFloat

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height

        let tl = max(0, min(topLeft, min(w, h) / 2))
        let tr = max(0, min(topRight, min(w, h) / 2))
        let bl = max(0, min(bottomLeft, min(w, h) / 2))
        let br = max(0, min(bottomRight, min(w, h) / 2))

        var p = Path()

        p.move(to: CGPoint(x: tl, y: 0))
        p.addLine(to: CGPoint(x: w - tr, y: 0))
        if tr > 0 {
            p.addArc(
                center: CGPoint(x: w - tr, y: tr),
                radius: tr,
                startAngle: .degrees(-90),
                endAngle: .degrees(0),
                clockwise: false
            )
        }

        p.addLine(to: CGPoint(x: w, y: h - br))
        if br > 0 {
            p.addArc(
                center: CGPoint(x: w - br, y: h - br),
                radius: br,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
        }

        p.addLine(to: CGPoint(x: bl, y: h))
        if bl > 0 {
            p.addArc(
                center: CGPoint(x: bl, y: h - bl),
                radius: bl,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )
        }

        p.addLine(to: CGPoint(x: 0, y: tl))
        if tl > 0 {
            p.addArc(
                center: CGPoint(x: tl, y: tl),
                radius: tl,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false
            )
        }

        p.closeSubpath()
        return p
    }
}

struct TopRoundedRectangle: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let r = max(0, min(radius, min(rect.width, rect.height) / 2))
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        if r > 0 {
            p.addArc(
                center: CGPoint(x: rect.minX + r, y: rect.minY + r),
                radius: r,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false
            )
        }
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        if r > 0 {
            p.addArc(
                center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
                radius: r,
                startAngle: .degrees(270),
                endAngle: .degrees(0),
                clockwise: false
            )
        }
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct ChatInputBar: View {
    @Binding var text: String
    @Binding var mode: ChatDetailView.ChatInputMode
    @ObservedObject var voiceIO: VoiceIO
    let scale: CGFloat
    let onMicTap: () -> Void
    let onKeyboardTap: () -> Void
    let onSendTap: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 12 * scale) {
                Button {
                    switch mode {
                    case .text:
                        onMicTap()
                    case .voice:
                        onKeyboardTap()
                    }
                } label: {
                    Image(systemName: mode == .text ? "microphone.fill" : "keyboard")
                        .font(.system(size: 22 * scale, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(width: 28 * scale, height: 28 * scale)
                }
                .buttonStyle(.plain)

                if mode == .text {
                    TextField("", text: $text, prompt: Text("Please Enter").foregroundColor(.white.opacity(0.5)))
                        .font(.system(size: 14 * scale))
                        .foregroundStyle(.white)
                } else {
                    HStack(spacing: 10 * scale) {
                        VoiceWaveform(level: voiceIO.level, scale: scale)
                            .frame(height: 20 * scale)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(voiceIO.recordingDurationText)
                            .font(.system(size: 12 * scale, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(minWidth: 28 * scale, alignment: .trailing)
                    }
                }
            }
            
            Spacer()
            
            Button {
                onSendTap()
            } label: {
                Image("more_detail_send_icon")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(.white)
                    .frame(width: 28 * scale, height: 28 * scale)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18 * scale)
        .padding(.vertical, 13 * scale)
        .background(
            RoundedRectangle(cornerRadius: 35 * scale, style: .continuous)
                .fill(Color.white.opacity(0.2))
        )
        .background(
            RoundedRectangle(cornerRadius: 35 * scale, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 35 * scale, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(1),
                            Color.white.opacity(0),
                            Color.white.opacity(1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 16 * scale)
        .padding(.top, 12 * scale)
    }
}

struct VoiceWaveform: View {
    let level: CGFloat
    let scale: CGFloat

    var body: some View {
        HStack(spacing: 4 * scale) {
            bar(heightFactor: 0.35)
            bar(heightFactor: 0.7)
            bar(heightFactor: 1.0)
            bar(heightFactor: 0.7)
            bar(heightFactor: 0.35)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.linear(duration: 0.08), value: level)
    }

    private func bar(heightFactor: CGFloat) -> some View {
        let minH: CGFloat = 6 * scale
        let maxH: CGFloat = 18 * scale
        let amplitude = minH + (maxH - minH) * max(0, min(1, level))

        return Capsule()
            .fill(Color.white.opacity(0.85))
            .frame(width: 3 * scale, height: max(minH, amplitude * heightFactor))
            .frame(height: maxH, alignment: .center)
    }
}

struct VoicePlaybackIndicator: View {
    let isPlaying: Bool
    let tint: Color
    let scale: CGFloat

    var body: some View {
        Group {
            if isPlaying {
                WeChatStylePlayingBars(tint: tint, scale: scale)
            } else {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 14 * scale, weight: .regular))
                    .foregroundStyle(tint)
            }
        }
        .frame(width: 18 * scale, height: 18 * scale)
    }
}

struct WeChatStylePlayingBars: View {
    let tint: Color
    let scale: CGFloat

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 2 * scale) {
                bar(phase: t, offset: 0.0)
                bar(phase: t, offset: 1.2)
                bar(phase: t, offset: 2.4)
            }
            .frame(width: 18 * scale, height: 18 * scale, alignment: .center)
        }
    }

    private func bar(phase: TimeInterval, offset: Double) -> some View {
        let minH: CGFloat = 4 * scale
        let maxH: CGFloat = 14 * scale
        let v = (sin(phase * 8.0 + offset) + 1.0) / 2.0
        let h = minH + (maxH - minH) * CGFloat(v)

        return Capsule()
            .fill(tint)
            .frame(width: 2 * scale, height: h)
            .frame(height: maxH, alignment: .center)
    }
}

final class VoiceIO: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    @Published var level: CGFloat = 0
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var playingURL: URL?

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var meterTimer: Timer?

    var hasRecordPermission: Bool {
        if #available(iOS 17.0, *) {
            return AVAudioApplication.shared.recordPermission == .granted
        } else {
            return AVAudioSession.sharedInstance().recordPermission == .granted
        }
    }

    func requestRecordPermission(_ completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
    }

    func startRecording() throws {
        stopPlayback()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try session.setActive(true, options: [])

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("voice_\(UUID().uuidString)")
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.delegate = self
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()
        recorder.record()

        self.recorder = recorder
        isRecording = true
        recordingDuration = 0
        startMetering()
    }

    func stopRecording() -> (url: URL, duration: TimeInterval)? {
        guard let recorder else { return nil }
        let duration = recorder.currentTime
        let url = recorder.url

        recorder.stop()
        self.recorder = nil
        isRecording = false
        stopMetering()
        level = 0
        recordingDuration = 0

        return (url: url, duration: duration)
    }

    func cancelRecording() {
        guard let recorder else {
            stopMetering()
            level = 0
            isRecording = false
            recordingDuration = 0
            return
        }

        let url = recorder.url
        recorder.stop()
        self.recorder = nil
        isRecording = false
        stopMetering()
        level = 0
        recordingDuration = 0
        try? FileManager.default.removeItem(at: url)
    }

    func play(url: URL) {
        do {
            stopPlayback()
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true, options: [])

            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            player.play()
            self.player = player
            playingURL = url
        } catch {
        }
    }

    func stopPlayback() {
        player?.stop()
        player = nil
        playingURL = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if self.player === player {
            self.player = nil
            playingURL = nil
        }
    }

    private func startMetering() {
        meterTimer?.invalidate()
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self else { return }
            guard let recorder else { return }
            recorder.updateMeters()
            let power = recorder.averagePower(forChannel: 0)
            let linear = pow(10, power / 20)
            let smoothed = min(1, max(0, linear))
            self.level = CGFloat(smoothed)
            self.recordingDuration = recorder.currentTime
        }
    }

    private func stopMetering() {
        meterTimer?.invalidate()
        meterTimer = nil
    }

    var recordingDurationText: String {
        if recordingDuration <= 0 {
            return "0s"
        }
        return "\(Int(ceil(recordingDuration)))s"
    }
}
