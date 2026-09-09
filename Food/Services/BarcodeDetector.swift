import UIKit
import Vision
import CoreImage

nonisolated enum BarcodeDetector {
    static func detect(in image: UIImage) async -> String? {
        await Task.detached(priority: .userInitiated) {
            let variants = prepareVariants(from: image)

            for variant in variants {
                if let code = detectBarcodes(in: variant) {
                    return code
                }
            }

            for variant in variants {
                if let code = detectBarcodeInText(in: variant) {
                    return code
                }
            }

            return nil
        }.value
    }

    private struct ImageVariant {
        let cgImage: CGImage
        let orientation: CGImagePropertyOrientation
    }

    private static func prepareVariants(from image: UIImage) -> [ImageVariant] {
        let normalized = image.normalized()
        guard let base = normalized.cgImage else { return [] }

        var variants: [ImageVariant] = [
            ImageVariant(cgImage: base, orientation: .up)
        ]

        let maxDimension = max(base.width, base.height)
        if maxDimension < 1200 {
            for factor: CGFloat in [2, 3, 4] {
                if let scaled = normalized.scaledNearest(factor: factor)?.cgImage {
                    variants.append(ImageVariant(cgImage: scaled, orientation: .up))
                }
            }
        }

        if let enhanced = normalized.enhancedForBarcode()?.cgImage {
            variants.append(ImageVariant(cgImage: enhanced, orientation: .up))
            if let scaled = normalized.enhancedForBarcode()?.scaledNearest(factor: 2)?.cgImage {
                variants.append(ImageVariant(cgImage: scaled, orientation: .up))
            }
        }

        if image.imageOrientation != .up, let cg = image.cgImage {
            variants.append(ImageVariant(cgImage: cg, orientation: image.visionOrientation))
        }

        return variants
    }

    private static func detectBarcodes(in variant: ImageVariant) -> String? {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.ean8, .ean13, .upce, .code128, .code39, .itf14, .qr, .pdf417]

        let handler = VNImageRequestHandler(
            cgImage: variant.cgImage,
            orientation: variant.orientation,
            options: [:]
        )

        do {
            try handler.perform([request])
            let rawCodes = request.results?
                .compactMap { ($0 as? VNBarcodeObservation)?.payloadStringValue } ?? []

            for raw in rawCodes {
                if let normalized = BarcodeNormalizer.normalize(raw) {
                    return normalized
                }
            }
            return rawCodes.first.flatMap { BarcodeNormalizer.normalize($0) }
        } catch {
            return nil
        }
    }

    private static func detectBarcodeInText(in variant: ImageVariant) -> String? {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(
            cgImage: variant.cgImage,
            orientation: variant.orientation,
            options: [:]
        )

        do {
            try handler.perform([request])
            let lines = request.results?.compactMap { $0.topCandidates(1).first?.string } ?? []
            return BarcodeNormalizer.extractFromTextLines(lines)
        } catch {
            return nil
        }
    }
}

nonisolated private extension UIImage {
    func normalized() -> UIImage {
        guard imageOrientation != .up else { return self }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    var visionOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }

    func scaledNearest(factor: CGFloat) -> UIImage? {
        guard factor > 0, let source = cgImage else { return nil }
        let width = Int((CGFloat(source.width) * factor).rounded())
        let height = Int((CGFloat(source.height) * factor).rounded())
        guard width > 0, height > 0 else { return nil }

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.interpolationQuality = .none
        context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let scaled = context.makeImage() else { return nil }
        return UIImage(cgImage: scaled, scale: scale, orientation: .up)
    }

    func enhancedForBarcode() -> UIImage? {
        guard let input = CIImage(image: self) else { return nil }
        let context = CIContext()

        let grayscale = input.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0,
            kCIInputContrastKey: 1.4,
            kCIInputBrightnessKey: 0.05
        ])

        guard let output = context.createCGImage(grayscale, from: grayscale.extent) else { return nil }
        return UIImage(cgImage: output, scale: scale, orientation: .up)
    }
}
