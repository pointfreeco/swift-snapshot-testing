#if os(iOS) || os(tvOS) || os(macOS) || os(watchOS) || os(visionOS)
import CoreGraphics

extension CGImage {

    func context(with data: UnsafeMutableRawPointer? = nil) -> CGContext? {
        let bytesPerRow = self.width * ImageContext.bytesPerPixel
        guard
            let colorSpace = ImageContext.colorSpace,
            let context = CGContext(
                data: data,
                width: self.width,
                height: self.height,
                bitsPerComponent: ImageContext.bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { return nil }

        context.draw(self, in: CGRect(x: 0, y: 0, width: self.width, height: self.height))
        return context
    }
}
#endif
