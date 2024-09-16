# Image Serialization Plugin

Image Serialization Plugin is a plugin based on the PluginAPI, it provides support for encoding and decoding images. It leverages the plugin architecture to extend its support for different image formats without needing to modify the core system.

Plugins that conform to the `ImageSerializationPlugin` protocol can be registered into the `PluginRegistry` and used to encode or decode images in different formats, such as PNG, JPEG, WebP, HEIC, and more.

When a plugin supporting a specific image format is available, the `ImageSerializer` can dynamically choose the correct plugin based on the image format required, ensuring modularity and scalability in image handling.


# Image Serialization Plugin

The **Image Serialization Plugin** extends the functionality of the SnapshotTesting library by enabling support for multiple image formats through a plugin architecture. This PluginAPI allows image encoding and decoding to be easily extended without modifying the core logic of the system.

## Overview

The **Image Serialization Plugin** provides an interface for encoding and decoding images in various formats. By conforming to both the `ImageSerialization` and `SnapshotTestingPlugin` protocols, it integrates with the broader plugin system, allowing for the seamless addition of new image formats. The default implementation supports PNG, but this architecture allows users to define custom plugins for other formats.

### Image Serialization Plugin Architecture

The **Image Serialization Plugin** relies on the PluginAPI that is a combination of protocols and a centralized registry to manage and discover plugins. The architecture allows for dynamic registration of image serialization plugins, which can be automatically discovered at runtime using the Objective-C runtime. This makes the system highly extensible, with plugins being automatically registered without the need for manual intervention.

#### Key Components:

1. **`ImageSerialization` Protocol**:
   - Defines the core methods for encoding and decoding images.
   - Requires plugins to specify the image format they support using the `ImageSerializationFormat` enum.
   - Provides methods for encoding (`encodeImage`) and decoding (`decodeImage`) images.

2. **`ImageSerializationFormat` Enum**:
   - Represents supported image formats.
   - Includes predefined formats such as `.png` and extensible formats through the `.plugins(String)` case, allowing for custom formats to be introduced via plugins.

3. **`ImageSerializer` Class**:
   - Responsible for encoding and decoding images using the registered plugins.
   - Retrieves available plugins from the `PluginRegistry` and uses the first matching plugin for the requested image format.
   - Provides default implementations for PNG encoding and decoding if no plugin is available for a given format.

#### Example Plugin Flow:

1. **Plugin Discovery**:
   - Plugins are automatically discovered at runtime through the Objective-C runtime, which identifies classes that conform to both the `ImageSerialization` and `SnapshotTestingPlugin` protocols.

2. **Plugin Registration**:
   - Each plugin registers itself with the `PluginRegistry`, allowing it to be retrieved when needed for image serialization.

3. **Image Encoding/Decoding**:
   - When an image needs to be serialized, the `ImageSerializer` checks the available plugins for one that supports the requested format.
   - If no plugin is found, it defaults to the built-in PNG encoding/decoding methods.

#### Extensibility

The plugin architecture allows developers to introduce new image formats without modifying the core SnapshotTesting library. By creating a new plugin that conforms to `ImageSerializationPlugin`, you can easily add support for additional image formats.

Here are a few example plugins demonstrating how to extend the library with new image formats:

- **[Image Serialization Plugin - HEIC](https://github.com/mackoj/swift-snapshot-testing-plugin-heic)**: Enables storing images in the `.heic` format, which reduces file sizes compared to PNG.
- **[Image Serialization Plugin - WEBP](https://github.com/mackoj/swift-snapshot-testing-plugin-webp)**: Allows storing images in the `.webp` format, which offers better compression than PNG.
- **[Image Serialization Plugin - JXL](https://github.com/mackoj/swift-snapshot-testing-plugin-jxl)**: Facilitates storing images in the `.jxl` format, which provides superior compression and quality compared to PNG.

## Usage

For example, if you want to use JPEG XL as a new image format for your snapshots, you can follow these steps. This approach applies to any image format as long as you have a plugin that conforms to `ImageSerializationPlugin`.

1. **Add the Dependency**: Include the appropriate image serialization plugin as a dependency in your `Package.swift` file. For JPEG XL, it would look like this:

    ```swift
    .package(url: "https://github.com/mackoj/swift-snapshot-testing-plugin-jxl.git", revision: "0.0.1"),
    ```

2. **Link to Your Test Target**: Add the image serialization plugin to your test target's dependencies:

    ```swift
    .product(name: "JXLImageSerializer", package: "swift-snapshot-testing-plugin-jxl"),
    ```

3. **Import and Set Up**: In your test file, import the serializer and configure the image format in the `setUp()` method:

    ```swift
    import JXLImageSerializer

    override class func setUp() {
        SnapshotTesting.imageFormat = JXLImageSerializer.imageFormat
    }
    ```

   Alternatively, you can specify the image format for individual assertions:

    ```swift
    assertSnapshot(of: label, as: .image(precision: 0.9, format: JXLImageSerializer.imageFormat))
    ```

This setup demonstrates how to integrate a specific image format plugin. Replace `JXLImageSerializer` with the appropriate plugin and format for other image formats.
