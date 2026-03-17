import SwiftUI

struct BannerView: View {
    let images: [String]
    let height: CGFloat
    @Binding var currentIndex: Int
    @Environment(\.scenePhase) private var scenePhase
    @State private var autoScrollToken = UUID()
    
    var body: some View {
        if images.isEmpty {
            Color.clear.frame(height: height)
        } else {
            TabView(selection: $currentIndex) {
                ForEach(0..<images.count, id: \.self) { index in
                    Image(images[index])
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .ignoresSafeArea(edges: .top)
            .task(id: autoScrollToken) {
                guard images.count > 1 else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    guard !Task.isCancelled else { return }
                    guard scenePhase == .active else { continue }
                    await MainActor.run {
                        withAnimation(.easeInOut) {
                            currentIndex = (currentIndex + 1) % images.count
                        }
                    }
                }
            }
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    autoScrollToken = UUID()
                }
            }
        }
    }
}

struct BannerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    BannerView(
        images: ["more_card_1", "more_card_2"],
        height: 400,
        currentIndex: .constant(0)
    )
}
    }
}
