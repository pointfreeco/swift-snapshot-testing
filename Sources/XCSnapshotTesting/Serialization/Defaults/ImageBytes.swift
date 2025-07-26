#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS) || os(macOS)
/// Represents a serializable image for snapshot testing.
///
/// `ImageBytes` wraps a `UIImage`or `NSImage` and provides serialization/deserialization capabilities,
/// enabling images to be compared in snapshot tests. Implements `BytesRepresentable`
/// to convert images to binary data (`Data`) and vice versa.
public struct ImageBytes: BytesRepresentable {

    fileprivate struct ImageScaleKey: DataSerializationConfigurationKey {
        static let defaultValue: Double = 1
    }

    #if os(macOS)
    public let rawValue: NSImage
    #else
    public let rawValue: UIKit.UIImage
    #endif

    /// Initializes an instance from image data in a `BytesContainer`.
    ///
    /// - Parameter container: Container holding the binary image data.
    /// - Throws: `BytesSerializationError` if deserialization fails (e.g., corrupted data).
    public init(from container: BytesContainer) throws {
        #if os(macOS)
        guard let image = SDKImage(data: try container.read()) else {
            throw BytesSerializationError()
        }
        #else
        guard
            let image = SDKImage(
                data: try container.read(),
                scale: container.configuration.imageScale
            )
        else {
            throw BytesSerializationError()
        }
        #endif
        self.rawValue = image
    }

    #if os(macOS)
    /// Initializes from a `NSImage`.
    ///
    /// - Parameter rawValue: Image to convert to bytes for snapshot testing.
    public init(rawValue: NSImage) {
        self.rawValue = rawValue
    }
    #else
    /// Initializes from a `UIImage`.
    ///
    /// - Parameter rawValue: Image to convert to bytes for snapshot testing.
    public init(rawValue: UIKit.UIImage) {
        self.rawValue = rawValue
    }
    #endif

    /// Serializes the image to binary data and writes it to the container.
    ///
    /// - Parameter container: Destination container for the image data.
    /// - Throws: Error if serialization fails (e.g., failed image-to-data conversion).
    public func serialize(to container: BytesContainer) throws {
        guard let data = rawValue.pngData() else {
            return
        }

        try container.write(data)
    }
}

// MARK: - DataSerializationConfiguration

extension DataSerializationConfiguration {

    /// Gets/sets the image scaling factor during serialization/deserialization.
    ///
    /// Controls how images are resized when converting to `Data` or reading from a `BytesContainer`.
    /// - Note: Default value is `1.0`.
    public var imageScale: Double {
        get { self[ImageBytes.ImageScaleKey.self] }
        set { self[ImageBytes.ImageScaleKey.self] = newValue }
    }
}

// MARK: - IdentitySyncSnapshot

extension IdentitySyncSnapshot<ImageBytes> {

    /// Default configuration for image snapshots.
    ///
    /// - Notes:
    ///   - Uses default values like `precision: 1` (strict comparison) and `perceptualPrecision: nil` (Color/tonal tolerance).
    ///   - Uses `ImageDiffAttachmentGenerator` for visual diffs.
    public static var image: Self {
        .image()
    }

    #if os(iOS) || os(tvOS) || os(macOS) || os(visionOS)
    /// Creates a custom image snapshot configuration with precision and scale settings.
    ///
    /// - Parameters:
    ///   - precision: Pixel tolerance for comparison (e.g., `0.95` allows 5% difference).
    ///   - perceptualPrecision: Color/tonal tolerance for perceptual comparison.
    ///
    /// - Example:
    ///   ```swift
    ///   let config = IdentitySyncSnapshot<ImageBytes>.image(
    ///       precision: 0.98
    ///   )
    ///   ```
    public static func image(
        precision: Float = 1,
        perceptualPrecision: Float = 1
    ) -> Self {
        .init(
            pathExtension: "png",
            attachmentGenerator: ImageDiffAttachmentGenerator(
                precision: precision,
                perceptualPrecision: perceptualPrecision
            )
        )
    }
    #else
    public static func image(
        precision: Float = 1
    ) -> Self {
        .init(
            pathExtension: "png",
            attachmentGenerator: ImageDiffAttachmentGenerator(
                precision: precision,
                perceptualPrecision: 1
            )
        )
    }
    #endif
}

// MARK: - IdentitySyncSnapshot

#if os(macOS)
extension SyncSnapshot where Input: NSImage, Output == ImageBytes {

    /// Default configuration for image snapshots.
    ///
    /// - Notes:
    ///   - Uses default values like `precision: 1` (strict comparison) and `perceptualPrecision: nil` (Color/tonal tolerance).
    ///   - Uses `ImageDiffAttachmentGenerator` for visual diffs.
    public static var image: SyncSnapshot<Input, Output> {
        .image()
    }

    /// Creates a custom image snapshot configuration with precision and scale settings.
    ///
    /// - Parameters:
    ///   - precision: Pixel tolerance for comparison (e.g., `0.95` allows 5% difference).
    ///   - perceptualPrecision: Color/tonal tolerance for perceptual comparison.
    ///
    /// - Example:
    ///   ```swift
    ///   let config = IdentitySyncSnapshot<ImageBytes>.image(
    ///       precision: 0.98
    ///   )
    ///   ```
    public static func image(
        precision: Float = 1,
        perceptualPrecision: Float = 1
    ) -> SyncSnapshot<Input, Output> {
        IdentitySyncSnapshot.image(
            precision: precision,
            perceptualPrecision: perceptualPrecision
        ).pullback { $0 }
    }
}
#else
extension SyncSnapshot where Input: UIImage, Output == ImageBytes {

    /// Default configuration for image snapshots.
    ///
    /// - Notes:
    ///   - Uses default values like `precision: 1` (strict comparison) and `perceptualPrecision: nil` (Color/tonal tolerance).
    ///   - Uses `ImageDiffAttachmentGenerator` for visual diffs.
    public static var image: SyncSnapshot<Input, ImageBytes> {
        .image()
    }

    #if os(iOS) || os(tvOS) || os(visionOS)
    /// Creates a custom image snapshot configuration with precision and scale settings.
    ///
    /// - Parameters:
    ///   - precision: Pixel tolerance for comparison (e.g., `0.95` allows 5% difference).
    ///   - perceptualPrecision: Color/tonal tolerance for perceptual comparison.
    ///
    /// - Example:
    ///   ```swift
    ///   let config = IdentitySyncSnapshot<ImageBytes>.image(
    ///       precision: 0.98
    ///   )
    ///   ```
    public static func image(
        precision: Float = 1,
        perceptualPrecision: Float = 1
    ) -> SyncSnapshot<Input, Output> {
        IdentitySyncSnapshot.image(
            precision: precision,
            perceptualPrecision: perceptualPrecision
        ).pullback { $0 }
    }
    #elseif os(watchOS)
    public static func image(
        precision: Float = 1
    ) -> SyncSnapshot<Input, Output> {
        IdentitySyncSnapshot.image(
            precision: precision
        ).pullback { $0 }
    }
    #endif
}
#endif
#endif
