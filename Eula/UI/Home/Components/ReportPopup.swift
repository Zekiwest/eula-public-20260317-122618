import SwiftUI

struct ReportPopup: View {
    var onSubmit: (String) -> Void
    var onCancel: () -> Void
    
    @State private var reasonText: String = ""
    @FocusState private var isFocused: Bool
    
    private let width: CGFloat = 343
    private let height: CGFloat = 452
    
    var body: some View {
        AppPopupScaffold(width: width, height: height) {
            Color.clear
                .onTapGesture {
                    isFocused = false
                }

            VStack(spacing: 20) {
                Text("Are you sure you want to report this content? Please provide a brief reason for your report.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .frame(width: 295, alignment: .leading)
                
                ZStack(alignment: .topLeading) {
                    if reasonText.isEmpty {
                        Text("Enter your reason here...")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.black.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    
                    TextEditor(text: $reasonText)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.black)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .focused($isFocused)
                }
                .frame(width: 294, height: 140)
                .background(
                    Color.black.opacity(0.1)
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white,
                                    .white.opacity(0),
                                    .white
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                
                VStack(spacing: 16) {
                    AppPopupActionButton(
                        title: "Submit Report",
                        color: Color(hexString: "81C8DC"),
                        width: 232,
                        height: 58,
                        fontSize: 14,
                        hasInnerHighlight: true
                    ) {
                        onSubmit(reasonText)
                    }
                    
                    AppPopupActionButton(
                        title: "Cancel",
                        color: Color(hexString: "ACB1D7"),
                        width: 232,
                        height: 58,
                        fontSize: 14,
                        hasInnerHighlight: true
                    ) {
                        onCancel()
                    }
                }
            }
        }
    }
}

struct ReportPopup_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    ZStack {
        Color.black.opacity(0.3).ignoresSafeArea()
        ReportPopup(onSubmit: { _ in }, onCancel: {})
    }
}
    }
}
