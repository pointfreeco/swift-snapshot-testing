# Plugins

SnapshotTesting offers a wide range of built-in snapshot strategies, and over the years, third-party developers have introduced new ones. However, when there’s a need for functionality that spans multiple strategies, plugins become essential.

## Overview

Plugins provide greater flexibility and extensibility by enabling shared behavior across different strategies without the need to duplicate code or modify each strategy individually. They can be dynamically discovered, registered, and executed at runtime, making them ideal for adding new functionality without altering the core system. This architecture promotes modularity and decoupling, allowing features to be easily added or swapped out without impacting existing functionality.

### Plugin architecture

The plugin architecture is designed around the concept of **dynamic discovery and registration**. Plugins conform to specific protocols, such as `SnapshotTestingPlugin`, and are registered automatically by the `PluginRegistry`. This registry manages plugin instances, allowing them to be retrieved by identifier or filtered by the protocols they conform to.

The primary components of the plugin system include:

- **Plugin Protocols**: Define the behavior that plugins must implement.
- **PluginRegistry**: Manages plugin discovery, registration, and retrieval.
- **Objective-C Runtime Integration**: Allows automatic discovery of plugins that conform to specific protocols.

The `PluginRegistry` is a singleton that registers plugins during its initialization. Plugins can be retrieved by their identifier or cast to specific types, allowing flexible interaction.

## ImageSerializer

The `ImageSerializer` is a plugin-based system that provides support for encoding and decoding images. It leverages the plugin architecture to extend its support for different image formats without needing to modify the core system.

Plugins that conform to the `ImageSerializationPlugin` protocol can be registered into the `PluginRegistry` and used to encode or decode images in different formats, such as PNG, JPEG, WebP, HEIC, and more.

When a plugin supporting a specific image format is available, the `ImageSerializer` can dynamically choose the correct plugin based on the image format required, ensuring modularity and scalability in image handling.
