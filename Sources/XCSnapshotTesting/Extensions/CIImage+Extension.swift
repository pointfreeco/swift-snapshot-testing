#if os(iOS) || os(tvOS) || os(macOS) || os(visionOS)
import Accelerate.vImage
import CoreImage.CIKernel
import MetalPerformanceShaders
@preconcurrency import Metal.MTLDevice

extension CIImage {

    func perceptuallyCompare(
        _ newValue: CIImage,
        pixelPrecision: Float,
        perceptualPrecision: Float
    ) -> String? {
        // Calculate the deltaE values. Each pixel is a value between 0-100.
        // 0 means no difference, 100 means completely opposite.
        let deltaOutputImage = self.applyingLabDeltaE(newValue)
        // Setting the working color space and output color space to NSNull disables color management. This is appropriate when the output
        // of the operations is computational instead of an image intended to be displayed.
        let context = CIContext(options: [.workingColorSpace: NSNull(), .outputColorSpace: NSNull()])
        let deltaThreshold = (1 - perceptualPrecision) * 100
        let actualPixelPrecision: Float
        var maximumDeltaE: Float = 0

        // Metal is supported by all iOS/tvOS devices (2013 models or later) and Macs (2012 models or later).
        // Older devices do not support iOS/tvOS 13 and macOS 10.15 which are the minimum versions of swift-snapshot-testing.
        // However, some virtualized hardware do not have GPUs and therefore do not support Metal.
        // In this case, macOS falls back to a CPU-based OpenGL ES renderer that silently fails when a Metal command is issued.
        // We need to check for Metal device support and fallback to CPU based vImage buffer iteration.
        if ThresholdImageProcessorKernel.isSupported {
            // Fast path - Metal processing
            guard
                let thresholdOutputImage = try? deltaOutputImage.applyingThreshold(deltaThreshold),
                let averagePixel = thresholdOutputImage.applyingAreaAverage().renderSingleValue(
                    in: context
                )
            else {
                return "Newly-taken snapshot's data could not be processed."
            }
            actualPixelPrecision = 1 - averagePixel
            if actualPixelPrecision < pixelPrecision {
                maximumDeltaE = deltaOutputImage.applyingAreaMaximum().renderSingleValue(in: context) ?? 0
            }
        } else {
            // Slow path - CPU based vImage buffer iteration
            guard let buffer = deltaOutputImage.render(in: context) else {
                return "Newly-taken snapshot could not be processed."
            }
            defer { buffer.free() }
            var failingPixelCount: Int = 0
            // rowBytes must be a multiple of 8, so vImage_Buffer pads the end of each row with bytes to meet the multiple of 0 requirement.
            // We must do 2D iteration of the vImage_Buffer in order to avoid loading the padding garbage bytes at the end of each row.
            //
            // NB: We are purposely using a verbose 'while' loop instead of a 'for in' loop.  When the
            //     compiler doesn't have optimizations enabled, like in test targets, a `while` loop is
            //     significantly faster than a `for` loop for iterating through the elements of a memory
            //     buffer. Details can be found in [SR-6983](https://github.com/apple/swift/issues/49531)
            let componentStride = MemoryLayout<Float>.stride
            var line = 0
            while line < buffer.height {
                defer { line += 1 }
                let lineOffset = buffer.rowBytes * line
                var column = 0
                while column < buffer.width {
                    defer { column += 1 }
                    let byteOffset = lineOffset + column * componentStride
                    let deltaE = buffer.data.load(fromByteOffset: byteOffset, as: Float.self)
                    if deltaE > deltaThreshold {
                        failingPixelCount += 1
                        if deltaE > maximumDeltaE {
                            maximumDeltaE = deltaE
                        }
                    }
                }
            }
            let failingPixelPercent =
                Float(failingPixelCount)
                / Float(deltaOutputImage.extent.width * deltaOutputImage.extent.height)
            actualPixelPrecision = 1 - failingPixelPercent
        }

        guard actualPixelPrecision < pixelPrecision else { return nil }
        // The actual perceptual precision is the perceptual precision of the pixel with the highest DeltaE.
        // DeltaE is in a 0-100 scale, so we need to divide by 100 to transform it to a percentage.
        let minimumPerceptualPrecision = 1 - min(maximumDeltaE / 100, 1)
        return """
            The percentage of pixels that match \(actualPixelPrecision) is less than required \(pixelPrecision)
            The lowest perceptual color precision \(minimumPerceptualPrecision) is less than required \(perceptualPrecision)
            """
    }
}

extension CIImage {

    fileprivate func applyingLabDeltaE(_ other: CIImage) -> CIImage {
        applyingFilter("CILabDeltaE", parameters: ["inputImage2": other])
    }

    fileprivate func applyingThreshold(_ threshold: Float) throws -> CIImage {
        try ThresholdImageProcessorKernel.apply(
            withExtent: extent,
            inputs: [self],
            arguments: [ThresholdImageProcessorKernel.inputThresholdKey: threshold]
        )
    }

    fileprivate func applyingAreaAverage() -> CIImage {
        applyingFilter("CIAreaAverage", parameters: [kCIInputExtentKey: extent])
    }

    fileprivate func applyingAreaMaximum() -> CIImage {
        applyingFilter("CIAreaMaximum", parameters: [kCIInputExtentKey: extent])
    }

    fileprivate func renderSingleValue(in context: CIContext) -> Float? {
        guard let buffer = render(in: context) else { return nil }
        defer { buffer.free() }
        return buffer.data.load(fromByteOffset: 0, as: Float.self)
    }

    fileprivate func render(in context: CIContext, format: CIFormat = CIFormat.Rh) -> vImage_Buffer? {
        // Some hardware configurations (virtualized CPU renderers) do not support 32-bit float output formats,
        // so use a compatible 16-bit float format and convert the output value to 32-bit floats.
        guard
            var buffer16 = try? vImage_Buffer(
                width: Int(extent.width),
                height: Int(extent.height),
                bitsPerPixel: 16
            )
        else { return nil }
        defer { buffer16.free() }
        context.render(
            self,
            toBitmap: buffer16.data,
            rowBytes: buffer16.rowBytes,
            bounds: extent,
            format: format,
            colorSpace: nil
        )
        guard
            var buffer32 = try? vImage_Buffer(
                width: Int(buffer16.width),
                height: Int(buffer16.height),
                bitsPerPixel: 32
            ),
            vImageConvert_Planar16FtoPlanarF(&buffer16, &buffer32, 0) == kvImageNoError
        else { return nil }
        return buffer32
    }
}

// Copied from https://developer.apple.com/documentation/coreimage/ciimageprocessorkernel
private final class ThresholdImageProcessorKernel: CIImageProcessorKernel {
    static let inputThresholdKey = "thresholdValue"
    static let device = MTLCreateSystemDefaultDevice()

    static var isSupported: Bool {
        guard let device = device else {
            return false
        }

        #if targetEnvironment(simulator)
        guard #available(iOS 14.0, tvOS 14.0, *) else {
            // The MPSSupportsMTLDevice method throws an exception on iOS/tvOS simulators < 14.0
            return false
        }
        #endif

        return MPSSupportsMTLDevice(device)
    }

    override class func process(
        with inputs: [CIImageProcessorInput]?,
        arguments: [String: Any]?,
        output: CIImageProcessorOutput
    ) throws {
        guard
            let device = device,
            let commandBuffer = output.metalCommandBuffer,
            let input = inputs?.first,
            let sourceTexture = input.metalTexture,
            let destinationTexture = output.metalTexture,
            let thresholdValue = arguments?[inputThresholdKey] as? Float
        else {
            return
        }

        let threshold = MPSImageThresholdBinary(
            device: device,
            thresholdValue: thresholdValue,
            maximumValue: 1.0,
            linearGrayColorTransform: nil
        )

        threshold.encode(
            commandBuffer: commandBuffer,
            sourceTexture: sourceTexture,
            destinationTexture: destinationTexture
        )
    }
}
#endif
