#if os(macOS) || os(iOS) || os(tvOS) || os(visionOS) || os(watchOS)
import CoreGraphics

enum ImageContext {
    static let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
    static let bitsPerComponent = 8
    static let bytesPerPixel = 4
}
#endif
