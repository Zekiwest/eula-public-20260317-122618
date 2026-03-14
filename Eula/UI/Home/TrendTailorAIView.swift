import SwiftUI

struct TrendTailorAIView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\EnvironmentValues.tabBarHiddenBinding) private var tabBarHiddenBinding
    @State private var inputText: String = ""
    @State private var resultText: String = ""
    @State private var mode: Mode = .input
    @State private var isSending = false
    @State private var sendTask: Task<Void, Never>?
    @State private var showToast = false
    @State private var toastMessage = ""

    enum Mode {
        case input
        case result
    }

    var body: some View {
        AppScreen {
            GeometryReader { proxy in
                let isSmallScreen = proxy.size.height <= 700

                ZStack(alignment: .topLeading) {
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 12) {
                            AppBackButton { dismiss() }

                            Text("TrendTailor AI")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .padding(.leading, 16)
                        .padding(.top, 10)

                        // Glame AI Module
                        ZStack(alignment: .topLeading) {
                            // Background
                            Image("drop_down_bg")
                                .resizable()
                                .frame(height: 164)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 20))

                            // Header Text
                            Text("Glame Al")
                                .font(.custom("Notable-Regular", size: 14))
                                .foregroundStyle(.white)
                                .offset(x: 16, y: 5)

                            // White Card
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)

                                // Text Content
                                VStack(alignment: .leading, spacing: 7) {
                                    Text("Hello! I'm your AI-powered makeup analysis robot.")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundStyle(Color(red: 247/255, green: 178/255, blue: 87/255))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.trailing, 120) // Avoid overlapping with woman image (approx 154 width)

                                    Text("You can send me a message below to ask me about different makeup combinations.")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundStyle(Color(red: 247/255, green: 178/255, blue: 87/255))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.trailing, 120) // Avoid overlapping with woman image
                                }
                                .padding(.leading, 16)
                                .padding(.top, 16)

                                // Woman Image (Aligned bottom-right)
                                GeometryReader { geometry in
                                    Image("ai_woman")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 154, height: 205)
                                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottomTrailing)
                                }
                            }
                            .frame(height: 136)
                            .frame(maxWidth: .infinity)
                            .offset(y: 28)
                        }
                        .frame(height: 164)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 48)
                        .padding(.horizontal, 20)

                        Group {
                            switch mode {
                            case .input:
                                TrendTailorChatArea(text: $inputText)
                            case .result:
                                TrendTailorResultArea(text: resultText)
                            }
                        }
                        .frame(height: 300)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                    // Bottom Button
                    VStack {
                        Spacer()
                        TrendTailorGetButton(
                            isCompact: isSmallScreen,
                            costCoins: AppConfig.trendTailorMessageCostCoins,
                            action: send
                        )
                        .disabled(isSending)
                        .padding(.bottom, isSmallScreen ? 24 : 58)
                    }
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(.all, edges: .bottom)
                }
            }
        }
        .navigationBarHidden(true)
        .overlay {
            AuthToastOverlay(isVisible: showToast, message: toastMessage, topPadding: 60)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                tabBarHiddenBinding?.wrappedValue = true
            }
        }
        .onDisappear {
            sendTask?.cancel()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                tabBarHiddenBinding?.wrappedValue = false
            }
        }
    }

    private func send() {
        if isSending {
            return
        }

        if mode == .result {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                mode = .input
                resultText = ""
            }
            return
        }

        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            AuthToast.show("Please enter your question.", showToast: $showToast, toastMessage: $toastMessage)
            return
        }

        inputText = ""

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            mode = .result
            resultText = ""
        }

        isSending = true
        sendTask?.cancel()
        sendTask = Task {
            do {
                try await ChatBackend.shared.stream(
                    conversationID: "trend_tailor_ai",
                    personaKey: "trendtailor",
                    messageCostCoins: AppConfig.trendTailorMessageCostCoins,
                    messages: [ChatHistoryMessage(role: .user, content: trimmed)],
                    onDelta: { delta in
                        appendDelta(delta)
                    }
                )
                await MainActor.run {
                    isSending = false
                }
            } catch is InsufficientCoinsError {
                await MainActor.run {
                    isSending = false
                    mode = .input
                    inputText = trimmed
                    resultText = ""
                    AuthToast.show("Insufficient coins. Please recharge your wallet.", showToast: $showToast, toastMessage: $toastMessage)
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    mode = .input
                    inputText = trimmed
                    resultText = ""
                    AuthToast.show("Request failed. Please try again.", showToast: $showToast, toastMessage: $toastMessage)
                }
            }
        }
    }

    @MainActor
    private func appendDelta(_ delta: String) {
        resultText += delta
    }
}

// TrendTailorChatArea moved to shared component
struct TrendTailorChatArea: View {
    @Binding var text: String
    var placeholder: String = "Tell me what style you want"
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background with Blur and Fill
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: .white, location: 0),
                                    .init(color: .white.opacity(0), location: 0.49),
                                    .init(color: .white, location: 1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            
            // Input TextEditor
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $text)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TrendTailorResultArea: View {
    let text: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: .white, location: 0),
                                    .init(color: .white.opacity(0), location: 0.49),
                                    .init(color: .white, location: 1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            ScrollView {
                Text(text)
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(.white)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            .scrollIndicators(.hidden)
        }
    }
}
