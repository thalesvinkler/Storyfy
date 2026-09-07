import CoreImage
import UIKit
import Vision

struct PhotoQualityAnalyzer {
    private let context = CIContext(options: [.cacheIntermediates: false])

    func visualScore(for image: UIImage) -> VisualQuality {
        guard let cgImage = image.cgImage else { return .neutral }
        let ciImage = CIImage(cgImage: cgImage)
        let exposure = exposureScore(for: ciImage)
        let sharpness = sharpnessScore(for: ciImage)
        let faces = faceScore(for: cgImage)
        return VisualQuality(exposure: exposure, sharpness: sharpness, faces: faces)
    }

    private func exposureScore(for image: CIImage) -> Double {
        let brightness = averageLuminance(of: image)
        return max(0, 1 - abs(brightness - 0.52) / 0.52)
    }

    private func sharpnessScore(for image: CIImage) -> Double {
        guard let edges = CIFilter(name: "CIEdges", parameters: [kCIInputImageKey: image, kCIInputIntensityKey: 1.4])?.outputImage else { return 0.5 }
        return min(1, averageLuminance(of: edges) * 5.5)
    }

    private func faceScore(for image: CGImage) -> Double {
        let request = VNDetectFaceRectanglesRequest()
        request.preferBackgroundProcessing = true
        try? VNImageRequestHandler(cgImage: image, orientation: .up).perform([request])
        let faces = request.results ?? []
        guard !faces.isEmpty else { return 0 }
        let largestArea = faces.map { $0.boundingBox.width * $0.boundingBox.height }.max() ?? 0
        let groupBonus = min(Double(faces.count - 1) * 0.08, 0.24)
        return min(1, 0.45 + min(largestArea * 2.5, 0.35) + groupBonus)
    }

    private func averageLuminance(of image: CIImage) -> Double {
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: image, kCIInputExtentKey: CIVector(cgRect: image.extent)]),
              let output = filter.outputImage else { return 0.5 }
        var pixel = [UInt8](repeating: 0, count: 4)
        context.render(output, toBitmap: &pixel, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        return (0.2126 * Double(pixel[0]) + 0.7152 * Double(pixel[1]) + 0.0722 * Double(pixel[2])) / 255
    }
}

struct VisualQuality {
    let exposure: Double
    let sharpness: Double
    let faces: Double

    static let neutral = VisualQuality(exposure: 0.5, sharpness: 0.5, faces: 0)
}
