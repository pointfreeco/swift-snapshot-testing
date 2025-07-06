import Foundation

#if os(iOS) || os(tvOS) || os(visionOS) || os(watchOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// A structure representing a snapshot attachment, including its uniform type identifier, name, and payload data.
///
/// This type is designed to encapsulate information about a snapshot, including its type, optional name, and binary payload.
/// It provides multiple initializers to create instances from different data types, such as `Data`, `String`, or platform-specific image types.
public struct SnapshotAttachment: Sendable {

    /// The uniform type identifier (UTI) for the snapshot attachment.
    ///
    /// This identifies the type of data contained in the payload. Defaults to `"public.data"` if not provided.
    public let uniformTypeIdentifier: String

    /// The optional name of the snapshot attachment.
    ///
    /// This can be used to provide a human-readable identifier for the attachment.
    public var name: String?

    /// The binary payload data of the snapshot.
    ///
    /// This represents the actual data stored in the attachment. May be `nil` if no data is provided.
    public let payload: Data?

    /// Initializes a `SnapshotAttachment` with a custom uniform type identifier, name, and payload.
    ///
    /// - Parameters:
    ///   - identifier: The uniform type identifier for the attachment. Defaults to `"public.data"` if `nil`.
    ///   - name: An optional name for the attachment.
    ///   - payload: The binary data payload. Defaults to `nil` if not provided.
    public init(uniformTypeIdentifier identifier: String?, name: String?, payload: Data?) {
        self.uniformTypeIdentifier = identifier ?? "public.data"
        self.name = name
        self.payload = payload
    }

    /// Initializes a `SnapshotAttachment` with raw data, using a default uniform type identifier.
    ///
    /// - Parameters:
    ///   - payload: The binary data to use as the payload.
    ///
    /// - SeeAlso: Uses `"public.data"` as the uniform type identifier.
    public init(data payload: Data) {
        self.init(
            data: payload,
            uniformTypeIdentifier: "public.data"
        )
    }

    /// Initializes a `SnapshotAttachment` with raw data and a specified uniform type identifier.
    ///
    /// - Parameters:
    ///   - payload: The binary data to use as the payload.
    ///   - identifier: The uniform type identifier for the attachment.
    public init(data payload: Data, uniformTypeIdentifier identifier: String) {
        self.init(
            uniformTypeIdentifier: identifier,
            name: "",
            payload: payload
        )
    }

    /// Initializes a `SnapshotAttachment` from a string, converting it to UTF-8 data.
    ///
    /// - Parameter:
    ///   - string: The string to use as the payload. Uses `"public.plain-text"` as the uniform type identifier.
    public init(string: String) {
        self.init(
            data: Data(string.utf8),
            uniformTypeIdentifier: "public.plain-text"
        )
    }

    #if os(iOS) || os(tvOS) || os(visionOS) || os(watchOS)
    /// Initializes a `SnapshotAttachment` from a platform-specific image (iOS/tvOS/visionOS/watchOS).
    ///
    /// - Parameter:
    ///   - image: The `UIImage` to convert to PNG data. Returns `nil` if conversion fails.
    public init?(image: UIImage) {
        guard let payload = image.pngData() else {
            return nil
        }

        self.init(
            uniformTypeIdentifier: "public.png",
            name: "",
            payload: payload
        )
    }
    #elseif os(macOS)
    /// Initializes a `SnapshotAttachment` from a platform-specific image (macOS).
    ///
    /// - Parameter:
    ///   - image: The `NSImage` to convert to PNG data. Returns `nil` if conversion fails.
    public init?(image: NSImage) {
        guard let payload = image.pngData() else {
            return nil
        }

        self.init(
            uniformTypeIdentifier: "public.png",
            name: "",
            payload: payload
        )
    }
    #endif
}
