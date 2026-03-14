import SwiftUI

struct ReportReasonPopup: View {
    @Binding var isPresented: Bool
    
    @State private var selectedReason: ReportReason? = .harassment
    @State private var otherReasonText: String = ""
    
    enum ReportReason: String, CaseIterable, Identifiable {
        case harassment = "Harassment"
        case inappropriateLanguage = "Inappropriate language"
        case spam = "Spam or false information"
        case other = "Other"
        
        var id: String { self.rawValue }
        
        var title: String {
            switch self {
            case .other:
                return "Other (please specify in the description box below)."
            default:
                return rawValue
            }
        }
    }
    
    var body: some View {
        ZStack {
            Image("TermsofUse_bg")
                .resizable(capInsets: EdgeInsets(top: 180, leading: 0, bottom: 150, trailing: 0), resizingMode: .stretch)
                .frame(width: 343, height: 585)
            
            VStack(spacing: 0) {
                Text("Please select the reason for reporting this user:")
                    .font(.system(size: 14))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                
                VStack(spacing: 18) {
                    ForEach(ReportReason.allCases) { reason in
                        ReasonRow(
                            reason: reason,
                            isSelected: selectedReason == reason,
                            action: { selectedReason = reason }
                        )
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)
                
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundColor(Color.black.opacity(0.1))
                        .overlay(
                            LinearGradient(
                                colors: [.white, .white.opacity(0), .white],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .mask(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(lineWidth: 1)
                            )
                        )
                    
                    if otherReasonText.isEmpty {
                        Text("Enter your reason here...")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.black.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    
                    TextEditor(text: $otherReasonText)
                        .font(.system(size: 14))
                        .foregroundStyle(.black)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                }
                .frame(width: 296, height: 140)
                .padding(.top, 20)
                
                VStack(spacing: 16) {
                    Button(action: {
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Text("Submit Report")
                            .font(.custom("Notable-Regular", size: 14))
                            .foregroundStyle(.white)
                            .frame(width: 232, height: 58)
                            .background(Color(hexString: "81C8DC"))
                            .clipShape(RoundedRectangle(cornerRadius: 40))
                            .overlay(
                                RoundedRectangle(cornerRadius: 40)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                            )
                            .shadow(color: .white.opacity(0.25), radius: 4, x: 0, y: 4)
                    }
                    
                    Button(action: {
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Text("Cancel")
                            .font(.custom("Notable-Regular", size: 14))
                            .foregroundStyle(.white)
                            .frame(width: 232, height: 58)
                            .background(Color(hexString: "ACB1D7"))
                            .clipShape(RoundedRectangle(cornerRadius: 40))
                            .overlay(
                                RoundedRectangle(cornerRadius: 40)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                            )
                            .shadow(color: .white.opacity(0.25), radius: 4, x: 0, y: 4)
                    }
                }
                .padding(.top, 16)
                
                Spacer()
            }
            .frame(width: 343, height: 585)
        }
    }
}

private struct ReasonRow: View {
    let reason: ReportReasonPopup.ReportReason
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .foregroundColor(isSelected ? Color(hexString: "FF8796") : Color.white)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 0)
                
                Text(reason.title)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hexString: "333333"))
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
        }
    }
}

struct ReportReasonPopup_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    ZStack {
        Color.black
        ReportReasonPopup(isPresented: .constant(true))
    }
}
    }
}
