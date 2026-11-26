import SwiftUI

struct CameraCaptureView: UIViewControllerRepresentable {
    @Binding var image: UIImage? //撮影した画像
    let overlayImage: UIImage? //ガイド画像
    let overlayMode: OverlayMode

    @Environment(\.dismiss) private var dismiss //画面を閉じるための情報を取得

    //カメラの設定
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator

        if overlayImage != nil {
            picker.loadViewIfNeeded()
            picker.cameraOverlayView = makeOverlayView(size: picker.view.bounds.size)
        }

        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: Context
    ) {
        // ガイド画像は makeUIViewController で設定済み
    }

    // 半透明のガイド画像を作成
    private func makeOverlayView(size: CGSize) -> UIView {
        guard let overlayImage else {
            return UIView(frame: CGRect(origin: .zero, size: size))
        }

        return DraggableGuideOverlayView(
            image: overlayImage,
            size: size,
            mode: overlayMode
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject,
        UINavigationControllerDelegate,
        UIImagePickerControllerDelegate {

        let parent: CameraCaptureView

        init(_ parent: CameraCaptureView) {
            self.parent = parent
        }

        //撮影が完了した時
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }

            parent.dismiss()
        }

        func imagePickerControllerDidCancel(
            _ picker: UIImagePickerController
        ) {
            parent.dismiss()
        }
    }
}


final class DraggableGuideOverlayView: UIView {

    private let imageView = UIImageView()
    private var dragStartCenter: CGPoint = .zero //ドラッグでの移動量
    private let snapThreshold: CGFloat = 5 //吸着の範囲
    private var lastSnapX: CGFloat?
    private var lastSnapY: CGFloat?
    private let mode: OverlayMode

    init(image: UIImage, size: CGSize, mode: OverlayMode) {
        self.mode = mode

        super.init(
            frame: CGRect(
                x: 0,
                y: 0,
                width: size.width,
                height: size.height * 0.9
            )
        )

        backgroundColor = .clear
       // isUserInteractionEnabled = true //ビューの操作

        imageView.image = image
        imageView.contentMode = .scaleAspectFit //画像の表示範囲

        // 線画と透明レイヤーで透明度を変える
        switch mode {
        case .lineArt:
            imageView.alpha = 1.0
        case .transparent:
            imageView.alpha = 0.4
        }

        imageView.isUserInteractionEnabled = true

        //画像の幅と高さを計算
        let imageWidth = size.width
        let imageHeight = imageWidth * image.size.height / image.size.width

        //画像の表示位置と大きさ
        imageView.frame = CGRect(
            x: (size.width - imageWidth) / 2,
            y: size.height * 0.14,
            width: imageWidth,
            height: imageHeight
        )

        addSubview(imageView)

        //二本指の検知
        let pan = UIPanGestureRecognizer(
            target: self,
            action: #selector(moveImage(_:))
        )
        pan.minimumNumberOfTouches = 2 //最低2本の指
        pan.maximumNumberOfTouches = 2 //最大2本の指

        imageView.addGestureRecognizer(pan) //画像にドラッグ操作を設定する
    }
    // 二本指で移動
    @objc private func moveImage(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began: //二本指のドラッグが始まったら
            dragStartCenter = imageView.center //画像の中心を記録
            gesture.setTranslation(.zero, in: self) //移動量をゼロにして、この時点を基準

        case .changed:
            let movement = gesture.translation(in: self)
            var x = dragStartCenter.x + movement.x
            let y = dragStartCenter.y + movement.y

            //中央に吸着
            let centerX = bounds.midX
            if abs(x - centerX) < snapThreshold {
                x = centerX                                                                                                
            }

            imageView.center = CGPoint(x: x, y: y)

        default:
            break
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
