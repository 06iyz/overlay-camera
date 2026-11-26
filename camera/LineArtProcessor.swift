import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import ImageIO

enum LineArtProcessor {
    private static let context = CIContext()

    static func makeLineArt(from image: UIImage) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
           format.scale = image.scale

        let normalizedImage = UIGraphicsImageRenderer(
            size: image.size,
            format: format
        ).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }

        guard let input = CIImage(image: normalizedImage) else {
            return nil
        }
      
        // 1. Visionで人物を検出する
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8

        let handler = VNImageRequestHandler(
            ciImage: input,
            options: [:]
        )

        do {
            try handler.perform([request])
        } catch {
            print("人物検出に失敗: \(error)")
            return nil
        }
        // 2. 人物のマスクを取得する
        guard let observation = request.results?.first else {
            return nil
        }

        let mask = CIImage(cvPixelBuffer: observation.pixelBuffer)

        // 3. マスクの外周を抽出する
        let edges = CIFilter.morphologyGradient()
        edges.inputImage = mask
        edges.radius = 2.0

        guard let edgeImage = edges.outputImage else {
            return nil
        }

        // 4. 輪郭を黒くし、背景を透明にする
        let black = CIImage(
            color: CIColor(red: 0, green: 0, blue: 0, alpha: 1)
        ).cropped(to: edgeImage.extent)

        let transparent = CIImage(
            color: CIColor(red: 0, green: 0, blue: 0, alpha: 0)
        ).cropped(to: edgeImage.extent)

        let blend = CIFilter.blendWithMask()
        blend.inputImage = black
        blend.backgroundImage = transparent
        blend.maskImage = edgeImage

        guard let result = blend.outputImage,
              let output = context.createCGImage(
                result,
                from: result.extent
              ) else {
            return nil
        }

        return UIImage(
            cgImage: output,
            scale: normalizedImage.scale,
            orientation: .up
        )
    }
}
