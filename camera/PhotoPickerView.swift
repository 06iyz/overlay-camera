
import SwiftUI

//変数の型
enum OverlayMode: String, CaseIterable {
    case lineArt = "線画"
    case transparent = "透明レイヤー"
}

struct PhotoPickerView: View {

    let previewImage: UIImage
    let isGuideFromCamera: Bool
    let saveMessage: String
    @Binding var overlayMode: OverlayMode
    @Binding var isShowingInstructions: Bool

    let onBack: () -> Void
    let onCapture: () -> Void
    let onReplaceGuide: () -> Void

    var body: some View {
        guideSettings(previewImage: previewImage)
    }

    private func guideSettings(previewImage: UIImage) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                guideHeader

                VStack(alignment: .leading, spacing: 10) {
                    Text("お手本を、撮影ガイドに。")
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text("写真の重ね方を選んで、撮影へ。")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.76))

                    guidePreview(previewImage)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 7) {
                        modeButton(.lineArt, title: "線画", icon: "square.dashed")
                        modeButton(.transparent, title: "透明", icon: "square.on.square.fill")
                    }
                    .padding(4)
                    //.background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 20))

                    Text(overlayMode == .lineArt
                         ? "人物の輪郭を線で重ねます。"
                         : "写真を半透明で重ねて、位置やポーズを合わせます。")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.76))
                }
                .padding(.top, 8)

                VStack(spacing: 12) {
                    guideAction("この写真をガイドにして撮影", icon: "camera", showsArrow: true) {
                        onCapture()
                    }

                    if isGuideFromCamera {
                        guideAction("写真を撮り直す", icon: "camera.rotate") {
                            onReplaceGuide()
                        }
                    } else {
                        guideAction("アルバムから選び直す", icon: "photo.on.rectangle") {
                            onReplaceGuide()
                        }
                    }
                }
                .padding(.top, 8)

                if !saveMessage.isEmpty {
                    Text(saveMessage)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.76))
                }
            }
            .frame(maxWidth: 480)
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .foregroundStyle(.white)
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private var guideHeader: some View {
        Text("KASANE")
            .font(.headline)
            .tracking(3)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                Button {
                    onBack()
                } label: {
                    Label("戻る", systemImage: "chevron.left")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 12)
                        .frame(minHeight: 25)
                }
                .buttonStyle(.glass)
            }
            .overlay(alignment: .trailing) {
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
            .frame(minHeight: 44)
    }

    private func guidePreview(_ photo: UIImage) -> some View {
        Image(uiImage: photo)
            .resizable()
            .scaledToFit()
            .opacity(overlayMode == .transparent ? 0.4 : 1)
            .accessibilityLabel("選択中のお手本画像")
            .background(Color(white: 0.94))
            //.clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(alignment: .topLeading) {
                Text("選択中のお手本")
                    .font(.caption.bold())
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.white, in: Capsule())
                    .padding(14)
            }
            .frame(maxHeight: 360)
    }

    private func modeButton(_ mode: OverlayMode, title: String, icon: String) -> some View {
        let isSelected = overlayMode == mode

        return Button {
            overlayMode = mode
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark")
                        .accessibilityHidden(true)
                }
            }
            .font(.subheadline.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(minHeight: 46)
            .glassEffect(
                isSelected
                    ? .regular.tint(.white.opacity(0.25)).interactive()
                    : .regular.interactive(),
                in: RoundedRectangle(cornerRadius: 20)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func guideAction(
        _ title: String,
        icon: String,
        showsArrow: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Label(title, systemImage: icon)
                if showsArrow {
                    Spacer(minLength: 8)
                    Image(systemName: "arrow.right")
                        .accessibilityHidden(true)
                }
            }
            .font(.headline)
            .foregroundStyle(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(.white, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

}


