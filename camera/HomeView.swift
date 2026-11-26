import SwiftUI
import AVKit
import Photos

struct HomeView: View {
    @State private var guideImage: UIImage?
    @State private var image: UIImage?
    @State private var isGuideFromCamera = false
    @State private var isSelectingGuide = true
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var overlayMode: OverlayMode = .lineArt
    @State private var saveMessage = ""
    @State private var pendingPhotoToSave: UIImage?
    
    @State private var isShowingInstructions = false
    @State private var isShowingDemo = false
    @State private var demoPlayer = Bundle.main
        .url(forResource: "GuideDemo", withExtension: "mp4")
        .map { AVPlayer(url: $0) }
    
    private let homeInk = Color(red: 0.08, green: 0.23, blue: 0.21)
    private let homeSecondary = Color(red: 0.34, green: 0.43, blue: 0.39)
    
    var body: some View {
        VStack(spacing: 0) {
            if let previewImage = cameraOverlayImage {
                PhotoPickerView(
                    previewImage: previewImage,
                    isGuideFromCamera: isGuideFromCamera,
                    saveMessage: saveMessage,
                    overlayMode: $overlayMode,
                    isShowingInstructions: $isShowingInstructions,
                    onBack: {
                        guideImage = nil
                        image = nil
                        saveMessage = ""
                    },
                    onCapture: {
                        isSelectingGuide = false
                        showCamera = true
                    },
                    onReplaceGuide: {
                        if isGuideFromCamera {
                            isSelectingGuide = true
                            showCamera = true
                        } else {
                            showLibrary = true
                        }
                    }
                )
            } else {
                homeContent
            }
        }
        .fullScreenCover(isPresented: $showCamera, onDismiss: {
            if isSelectingGuide, guideImage != nil {
                isSelectingGuide = false
            }

            guard let photo = pendingPhotoToSave else { return }
            pendingPhotoToSave = nil
            Task {
                await savePhoto(photo)
            }
        }) {
            CameraCaptureView(
                image: isSelectingGuide ? $guideImage : capturedPhotoBinding,
                overlayImage: isSelectingGuide ? nil : cameraOverlayImage,
                overlayMode: overlayMode
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showLibrary) {
            PhotoLibraryPickerView(image: $guideImage)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingInstructions) {
            NavigationStack {
                ScrollView {
                    instructions
                        .padding(24)
                }
                .navigationTitle("使い方")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("閉じる") {
                            isShowingInstructions = false
                        }
                    }
                }
            }
            .presentationDragIndicator(.visible)
        }
    }

    // カメラに渡す画像を選択
    private var cameraOverlayImage: UIImage? {
        guard let guideImage else {
            return nil
        } //写真があるかの確認

        switch overlayMode {
        case .lineArt:
            return LineArtProcessor.makeLineArt(from: guideImage)
                ?? guideImage

        case .transparent:
            return guideImage
        }
    }//cameraOverlayImage
    
    private func savePhoto(_ photo: UIImage) async {
        saveMessage = ""

        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized else {
            saveMessage = "設定アプリから、写真への追加を許可してください。"
            return
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                _ = PHAssetChangeRequest.creationRequestForAsset(from: photo)
            }
            saveMessage = "写真アプリに保存しました。"
        } catch {
            saveMessage = "保存できませんでした。もう一度お試しください。"
        }
    }//savePhoto
    
    private var capturedPhotoBinding: Binding<UIImage?> {
        Binding(
            get: { image },
            set: { newPhoto in
                image = newPhoto
                pendingPhotoToSave = newPhoto
            }
        )
    }

    private var homeContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("OVERLAY")
                            .font(.title3.bold())
                            .tracking(3)
                        Text("重ねて撮れるカメラ")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    Spacer()
                    Button {
                        isShowingInstructions = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("使い方を表示")
                }

                Text("好きな構図で、\n撮ってもらおう。")
                    .font(.title.bold())
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, 30)

               Image("Image")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)

                VStack(spacing: 12) {
                    homeButton(
                        "カメラで撮る",
                        subtitle: "お手本にしたい写真を新しく撮影",
                        icon: "camera",
                        primary: true
                    ) {
                        isGuideFromCamera = true
                        isSelectingGuide = true
                        showCamera = true
                    }

                    homeButton(
                        "アルバムから選ぶ",
                        subtitle: "お手本にしたい写真からはじめる",
                        icon: "photo.on.rectangle",
                        primary: false
                    ) {
                        isGuideFromCamera = false
                        isSelectingGuide = false
                        showLibrary = true
                    }
                }
            }
            .frame(maxWidth: 420)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .padding(.top, 36)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .foregroundStyle(.white)
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
    
    
    private func homeButton(
        _ title: String,
        subtitle: String,
        icon: String,
        primary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let ink = primary ? Color(white: 0.15) : homeInk

        return Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(primary ? Color(white: 0.40) : homeSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "arrow.right")
            }
            .foregroundStyle(ink)
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(homeInk.opacity(primary ? 0 : 0.18))
            }
        }
        .buttonStyle(.plain)
    }//homeButton
    
    private var instructions: some View {
        VStack(alignment: .leading, spacing: 14) {
            instructionStep(1, "お手本の画像を選ぶ", detail: "カメラで撮るか、アルバムから選ぶ。")
            Divider()
            instructionStep(2, "半透明か線画を選択", detail: "ガイドの表示方法を選ぶ。")
            Divider()
            instructionStep(3, "ガイドに重ねて合わせる", detail: "位置やポーズをお手本に近づける。")
            Divider()
            instructionStep(4, "撮影した写真を確認", detail: "シャッターを押し、「Use」で確定する。")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }//instructions
    
    private func instructionStep(_ number: Int, _ title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number.formatted())
                .font(.caption.bold())
                .frame(width: 28, height: 28)
                .background(.quaternary, in: Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }//instructionStep
}


