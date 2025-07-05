#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS) || os(visionOS)
typealias SDKImage = UIKit.UIImage
typealias SDKLabel = UIKit.UILabel
typealias SDKView = UIKit.UIView
typealias SDKViewController = UIKit.UIViewController
typealias SDKApplication = UIKit.UIApplication
typealias SDKWindow = UIKit.UIWindow
#elseif os(watchOS)
typealias SDKImage = UIKit.UIImage
#elseif os(macOS)
typealias SDKImage = AppKit.NSImage
typealias SDKLabel = AppKit.NSText
typealias SDKView = AppKit.NSView
typealias SDKViewController = AppKit.NSViewController
typealias SDKApplication = AppKit.NSApplication
typealias SDKWindow = AppKit.NSWindow
#endif

#if os(iOS) || os(tvOS) || os(visionOS) || os(watchOS) || os(macOS)
extension SDKImage {

    #if os(macOS)
    var scale: CGFloat {
        1.0
    }

    var cgImage: CGImage? {
        guard
            let pngData = pngData(),
            let dataProvider = CGDataProvider(data: pngData as CFData)
        else { return nil }

        return CGImage(
            pngDataProviderSource: dataProvider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }

    func pngData() -> Data? {
        performOnMainThread {
            guard
                let bitmapRep = NSBitmapImageRep(
                    bitmapDataPlanes: nil,
                    pixelsWide: Int(size.width),
                    pixelsHigh: Int(size.height),
                    bitsPerSample: 8,
                    samplesPerPixel: 4,
                    hasAlpha: true,
                    isPlanar: false,
                    colorSpaceName: .calibratedRGB,
                    bytesPerRow: 0,
                    bitsPerPixel: 0
                ),
                let context = NSGraphicsContext(bitmapImageRep: bitmapRep)
            else { return nil }

            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = context
            draw(in: NSRect(origin: .zero, size: size))
            NSGraphicsContext.restoreGraphicsState()

            return bitmapRep.representation(using: .png, properties: [:])
        }
    }
    #endif

    /// Used when the image size has no width or no height to generated the default empty image
    @MainActor
    static var empty: SDKImage {
        #if os(iOS) || os(tvOS) || os(macOS)
        let label = SDKLabel(frame: CGRect(x: 0, y: 0, width: 400, height: 80))
        let text =
            "Error: No image could be generated for this view as its size was zero. Please set an explicit size in the test."
        label.backgroundColor = .red
        #if os(macOS)
        label.string = text
        label.alignment = .center
        label.isVerticallyResizable = true
        #else
        label.text = text
        label.textAlignment = .center
        label.numberOfLines = 3
        #endif
        return label.asImage()
        #else
        return SDKImage()
        #endif
    }

    @MainActor
    func substract(_ image: SDKImage) -> SDKImage {
        #if os(macOS)
        guard let lhsImage = cgImage, let rhsImage = image.cgImage else {
            return SDKImage()
        }

        let oldCiImage = CIImage(cgImage: lhsImage)
        let newCiImage = CIImage(cgImage: rhsImage)
        let differenceFilter = CIFilter(name: "CIDifferenceBlendMode")!
        differenceFilter.setValue(oldCiImage, forKey: kCIInputImageKey)
        differenceFilter.setValue(newCiImage, forKey: kCIInputBackgroundImageKey)
        let maxSize = CGSize(
            width: max(size.width, image.size.width),
            height: max(size.height, image.size.height)
        )
        let rep = NSCIImageRep(ciImage: differenceFilter.outputImage!)
        let difference = NSImage(size: maxSize)
        difference.addRepresentation(rep)
        return difference
        #else
        let width = max(self.size.width, image.size.width)
        let height = max(self.size.height, image.size.height)
        let scale = max(self.scale, image.scale)
        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), true, scale)
        image.draw(in: .init(origin: .zero, size: size))
        self.draw(in: .init(origin: .zero, size: size), blendMode: .difference, alpha: 1)
        let differenceImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return differenceImage
        #endif
    }

    @MainActor
    func compare(_ newValue: SDKImage, precision: Float, perceptualPrecision: Float) -> String? {
        guard let oldCgImage = self.cgImage else {
            return "Reference image could not be loaded."
        }
        guard let newCgImage = newValue.cgImage else {
            return "Newly-taken snapshot could not be loaded."
        }
        guard newCgImage.width != 0, newCgImage.height != 0 else {
            return "Newly-taken snapshot is empty."
        }
        guard oldCgImage.width == newCgImage.width, oldCgImage.height == newCgImage.height else {
            return "Newly-taken snapshot@\(newValue.size) does not match reference@\(self.size)."
        }
        let pixelCount = oldCgImage.width * oldCgImage.height
        let byteCount = ImageContext.bytesPerPixel * pixelCount
        var oldBytes = [UInt8](repeating: 0, count: byteCount)
        guard let oldData = oldCgImage.context(with: &oldBytes)?.data else {
            return "Reference image's data could not be loaded."
        }
        if let newContext = newCgImage.context(), let newData = newContext.data {
            if memcmp(oldData, newData, byteCount) == 0 { return nil }
        }
        var newerBytes = [UInt8](repeating: 0, count: byteCount)
        guard
            let pngData = newValue.pngData(),
            let newerCgImage = SDKImage(data: pngData)?.cgImage,
            let newerContext = newerCgImage.context(with: &newerBytes),
            let newerData = newerContext.data
        else {
            return "Newly-taken snapshot's data could not be loaded."
        }
        if memcmp(oldData, newerData, byteCount) == 0 { return nil }
        if precision >= 1, perceptualPrecision >= 1 {
            return "Newly-taken snapshot does not match reference."
        }
        #if os(iOS) || os(tvOS) || os(macOS)
        if perceptualPrecision < 1, #available(iOS 11.0, tvOS 11.0, *) {
            return CIImage(cgImage: oldCgImage).perceptuallyCompare(
                CIImage(cgImage: newCgImage),
                pixelPrecision: precision,
                perceptualPrecision: perceptualPrecision
            )
        }
        #endif

        let byteCountThreshold = Int((1 - precision) * Float(byteCount))
        var differentByteCount = 0
        // NB: We are purposely using a verbose 'while' loop instead of a 'for in' loop.  When the
        //     compiler doesn't have optimizations enabled, like in test targets, a `while` loop is
        //     significantly faster than a `for` loop for iterating through the elements of a memory
        //     buffer. Details can be found in [SR-6983](https://github.com/apple/swift/issues/49531)
        var index = 0
        while index < byteCount {
            defer { index += 1 }
            if oldBytes[index] != newerBytes[index] {
                differentByteCount += 1
            }
        }
        if differentByteCount > byteCountThreshold {
            let actualPrecision = 1 - Float(differentByteCount) / Float(byteCount)
            return "Actual image precision \(actualPrecision) is less than required \(precision)"
        }

        return nil
    }
}
#endif
