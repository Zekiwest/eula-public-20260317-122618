import SwiftUI

struct ReportPopup: View {
    var onSubmit: (String) -> Void
    var onCancel: () -> Void
    
    @State private var reasonText: String = ""
    @FocusState private var isFocused: Bool
    
    private let width: CGFloat = 343
    private let height: CGFloat = 452
    
    var body: some View {
        ZStack {
            Image("TermsofUse_bg")
                .resizable(capInsets: EdgeInsets(top: 180, leading: 0, bottom: 150, trailing: 0), resizingMode: .stretch)
                .frame(width: width, height: height)
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
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onSubmit(reasonText)
                    }) {
                        Text("Submit Report")
                            .font(.custom("Notable-Regular", size: 14))
                            .foregroundColor(.white)
                            .frame(width: 232, height: 58)
                            .background(Color(hexString: "81C8DC"))
                            .cornerRadius(40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 40)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 40)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 4)
                                    .blur(radius: 2)
                                    .offset(y: 2)
                                    .mask(
                                        RoundedRectangle(cornerRadius: 40)
                                            .fill(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom))
                                    )
                                    .allowsHitTesting(false)
                            )
                    }
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onCancel()
                    }) {
                        Text("Cancel")
                            .font(.custom("Notable-Regular", size: 14))
                            .foregroundColor(.white)
                            .frame(width: 232, height: 58)
                            .background(Color(hexString: "ACB1D7"))
                            .cornerRadius(40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 40)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 40)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 4)
                                    .blur(radius: 2)
                                    .offset(y: 2)
                                    .mask(
                                        RoundedRectangle(cornerRadius: 40)
                                            .fill(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom))
                                    )
                                    .allowsHitTesting(false)
                            )
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
