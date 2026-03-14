import SwiftUI
import PhotosUI
import AVFoundation

struct MakeupShareView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @State private var selectedVideoURL: URL? = nil
    
    var body: some View {
        AppScreen {
            CreatePostScaffold(onBack: { dismiss() }) { isSmallScreen in
                TrendTailorChatArea(
                    text: $text,
                    placeholder: "Details: Share your thoughts on this makeup look! Add color to the charm of the video with your words."
                )
                .frame(height: 300)
                .padding(.horizontal, 20)
                .padding(.top, 26)

                TrendTailorVideoUploadSection(
                    selectedVideoURL: $selectedVideoURL
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)

                MakeupSharePostButton {
                    dismiss()
                }
                .padding(.top, 40)
                .padding(.bottom, isSmallScreen ? 24 : 58)
            }
        }
        .navigationBarHidden(true)
    }
}

struct MakeupSharePostButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("POST")
                .font(.custom("Notable-Regular", size: 16))
                .foregroundStyle(.white)
                .frame(width: 238, height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 40)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color(red: 255/255, green: 135/255, blue: 150/255), location: 0.32),
                                    .init(color: Color(red: 247/255, green: 178/255, blue: 87/255), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(Color.white.opacity(0.25), lineWidth: 4)
                                .blur(radius: 4)
                                .mask(
                                    RoundedRectangle(cornerRadius: 40)
                                        .fill(
                                            LinearGradient(
                                                colors: [.black, .clear, .black],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 40))
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 40)
                        .strokeBorder(Color.white.opacity(0.4), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 4)
        }
    }
}

struct TrendTailorVideoUploadSection: View {
    @Binding var selectedVideoURL: URL?
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var thumbnail: UIImage? = nil

    var backgroundOpacity: Double = 0.1
    var uploadIconName: String = "upload_video_icon"
    var usesFullImage: Bool = false
    var placeholderImageName: String? = nil
    var showsDeleteButton: Bool = true

    var body: some View {
        HStack(spacing: 16) {
            if selectedVideoURL == nil {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .videos,
                    photoLibrary: .shared()
                ) {
                    if usesFullImage {
                        Image(uploadIconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 129, height: 146)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(backgroundOpacity))
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 20))

                            Image(uploadIconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                        }
                        .frame(width: 129, height: 146)
                    }
                }
                .buttonStyle(.plain)
                .onChange(of: selectedItem, perform: { newItem in
                    guard let newItem else { return }
                    Task {
                        let url = await loadVideoURL(from: newItem)
                        await MainActor.run {
                            selectedVideoURL = url
                        }
                    }
                })
            } else {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(backgroundOpacity))
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Group {
                        if let thumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFill()
                        } else if let placeholderImageName {
                            Image(placeholderImageName)
                                .resizable()
                                .scaledToFit()
                        } else {
                            VStack {
                                Spacer()
                                Image(systemName: "video.fill")
                                    .font(.system(size: 32, weight: .regular))
                                    .foregroundStyle(Color.black.opacity(0.85))
                                Spacer()
                            }
                        }
                    }
                    .frame(width: 129, height: 146)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    if showsDeleteButton {
                        Button(action: {
                            selectedVideoURL = nil
                            selectedItem = nil
                            thumbnail = nil
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.black.opacity(0.75))

                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 28, height: 28)
                        }
                    }
                }
                .frame(width: 129, height: 146)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: selectedVideoURL) {
            guard let selectedVideoURL else {
                thumbnail = nil
                return
            }

            thumbnail = await generateThumbnail(for: selectedVideoURL)
        }
    }

    private func generateThumbnail(for url: URL) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 600, height: 600)

            let time = CMTime(seconds: 0.0, preferredTimescale: 600)
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, _ in
                if let image {
                    continuation.resume(returning: UIImage(cgImage: image))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func loadVideoURL(from item: PhotosPickerItem) async -> URL? {
        if let data = try? await item.loadTransferable(type: Data.self) {
            return writeToTemporary(data: data)
        }

        if let url = try? await item.loadTransferable(type: URL.self) {
            return copyToTemporary(url: url)
        }

        return nil
    }

    private func copyToTemporary(url: URL) -> URL? {
        let fileExtension = url.pathExtension.isEmpty ? "mov" : url.pathExtension
        let targetURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(fileExtension)

        do {
            if FileManager.default.fileExists(atPath: targetURL.path) {
                try FileManager.default.removeItem(at: targetURL)
            }
            try FileManager.default.copyItem(at: url, to: targetURL)
            return targetURL
        } catch {
            return url
        }
    }

    private func writeToTemporary(data: Data) -> URL? {
        let targetURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        do {
            try data.write(to: targetURL, options: [.atomic])
            return targetURL
        } catch {
            return nil
        }
    }
}
