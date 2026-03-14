import SwiftUI
import Combine

final class ToastManager: ObservableObject {
    static let shared = ToastManager()
    @Published var message: String?
    @Published var isShowing = false
    
    private var hideTask: Task<Void, Never>?
    
    func show(_ message: String) {
        hideTask?.cancel()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            self.message = message
            self.isShowing = true
        }
        
        hideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                self.isShowing = false
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            self.message = nil
        }
    }
}

struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

struct ToastModifier: ViewModifier {
    @StateObject private var manager = ToastManager.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message = manager.message {
                    ToastView(message: message)
                        .padding(.bottom, 100)
                        .offset(y: manager.isShowing ? 0 : 100)
                        .opacity(manager.isShowing ? 1 : 0)
                }
            }
    }
}

extension View {
    func toast() -> some View {
        modifier(ToastModifier())
    }
}
