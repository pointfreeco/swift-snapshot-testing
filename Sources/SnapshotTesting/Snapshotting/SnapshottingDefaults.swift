import Foundation

/// The global configuration options
public enum SnapshottingDefaults {
    /// The default subdirectory for snapshots in the same directory as the test file. Defaults to `__Snapshots__` that sits next to your test file. Only used when `snapshotDirectory` is nil.
    public static var snapshotSubdirectory = "__Snapshots__"
    /// Optional directory to save snapshots. By default snapshots will be saved in a directory with the same name as the test file, and that directory will sit inside a directory `__Snapshots__` that sits next to your test file.
    public static var snapshotDirectory: String? = nil
    /// The amount of time a snapshot must be generated in.
    public static var timeout: TimeInterval = 5
    /// The percentage of pixels that must match. Value between 0-1
    public static var precision: Float = 1
    /// The percentage a pixel must match the source pixel to be considered a match. [98-99% mimics the precision of the human
    public static var perceptualPrecision: Float = 1
}
