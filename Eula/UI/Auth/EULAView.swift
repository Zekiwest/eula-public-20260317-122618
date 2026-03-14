import SwiftUI

/**
 * [INPUT]: 依赖 AppScreen, AppBackButton, Assets (EULA_Illustration, EULA_BackIcon, TermsofUse_bg)
 * [OUTPUT]: 对外提供 EULAView
 * [POS]: UI/Auth 模块的 EULA 协议展示页
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */
struct EULAView: View {
    let onBack: () -> Void
    let onSure: () -> Void
    
    // 颜色常量 (Figma 1:1)
    private let colorCancelBtn = Color(hexString: "FF8796") // 主色1
    private let colorSureBtn = Color(hexString: "ACB1D7")   // 主色2
    private let colorText = Color.black
    private let colorLinks = Color(hexString: "1ACDFF") // 辅助色
    
    var body: some View {
        GeometryReader { geometry in
            let isSmallScreen = geometry.size.height < 700
            
            AppScreen {
                ZStack {
                    VStack {
                        HStack {
                            AppBackButton(action: onBack)
                            Spacer()
                        }
                        .padding(.leading, 16)
                        .padding(.top, geometry.safeAreaInsets.top + 54)
                        Spacer()
                    }
                    .zIndex(10)
                    
                    VStack {
                        Spacer()
                        
                        ZStack(alignment: .top) {
                            VStack(spacing: 0) {
                                Spacer().frame(height: 80)
                                
                                VStack(spacing: isSmallScreen ? 10 : 20) {
                                    Text("EULA")
                                        .font(.custom("Notable-Regular", size: 16))
                                        .foregroundColor(.black)
                                    
                                    AppScrollView {
                                        Text("""
Welcome to Glame. To keep our community safe, the following content is prohibited:

1. Any content involving child sexual abuse or exploitation.

2. False or harmful information related to ongoing or recent events.

3. Violent, abusive, bullying, or pornographic content.

If we find content that violates these rules, we may remove the content and suspend or ban the account.

By tapping “Agree,” you accept the Terms of Use and Privacy Policy.
""")
                                        .font(.system(size: 14))
                                        .foregroundColor(.black)
                                        .lineSpacing(4)
                                        .multilineTextAlignment(.leading)
                                    }
                                    
                                    Spacer(minLength: isSmallScreen ? 5 : 10)
                                    
                                    HStack(spacing: 34) {
                                        NavigationLink(value: AuthRoute.userAgreement) {
                                            Text("Terms of Use")
                                                .font(.system(size: 15))
                                                .foregroundColor(colorLinks)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityIdentifier("eula_terms_of_use_link")
                                        
                                        NavigationLink(value: AuthRoute.privacyPolicy) {
                                            Text("Privacy Policy")
                                                .font(.system(size: 15))
                                                .foregroundColor(colorLinks)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityIdentifier("eula_privacy_policy_link")
                                    }
                                    
                                    HStack(spacing: 15) {
                                        Button(action: onBack) {
                                            Text("Cancel")
                                                .font(.custom("Notable-Regular", size: 14))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 48)
                                                .background(colorCancelBtn)
                                                .cornerRadius(40)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 40)
                                                        .stroke(Color.white, lineWidth: 1)
                                                )
                                        }
                                        
                                        Button(action: onSure) {
                                            Text("Agree")
                                                .font(.custom("Notable-Regular", size: 14))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 48)
                                                .background(colorSureBtn)
                                                .cornerRadius(40)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 40)
                                                        .stroke(Color.white, lineWidth: 1)
                                                )
                                        }
                                    }
                                    .padding(.bottom, isSmallScreen ? 20 : 30)
                                }
                                .padding(.horizontal, 24)
                            }
                            .frame(width: 343)
                            .frame(height: min(609, geometry.size.height * (isSmallScreen ? 0.70 : 0.85)))
                            .background(
                                Image("TermsofUse_bg")
                                    .resizable(capInsets: EdgeInsets(top: 180, leading: 0, bottom: 150, trailing: 0), resizingMode: .stretch)
                            )
                            .cornerRadius(20)
                            
                            Image("EULA_Illustration")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 254)
                                .offset(y: -60)
                        }
                        .padding(.bottom, isSmallScreen ? 15 : max(geometry.safeAreaInsets.bottom + 20, 50))
                    }
                }
            }
        }
        .ignoresSafeArea(.all, edges: .all) // 让 GeometryReader 读取全屏尺寸，我们自己处理 safeArea
        .navigationBarHidden(true)
    }
}

struct EULAView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    EULAView(onBack: {}, onSure: {})
}
    }
}
