#if os(macOS)
  import AppKit
  import Cocoa

  extension Snapshotting where Value == NSBezierPath, Format == NSImage {
    /// A snapshot strategy for comparing bezier paths based on pixel equality.
    public static var image: Snapshotting {
      return .image()
    }

    /// A snapshot strategy for comparing bezier paths based on pixel equality.
    ///
    ///``` swift
    /// // Match reference perfectly.
    /// assertSnapshot(of: path, as: .image)
    ///
    /// // Allow for a 1% pixel difference.
    /// assertSnapshot(of: path, as: .image(precision: 0.99))
    /// ```
    ///
    /// - Parameters:
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
    ///     match. 98-99% mimics
    ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
    ///     human eye.
    public static func image(precision: Float = 1, perceptualPrecision: Float = 1) -> Snapshotting {
      return SimplySnapshotting.image(
        precision: precision, perceptualPrecision: perceptualPrecision
      ).pullback { path in
        // Move path info frame:
        let bounds = path.bounds
        let transform = AffineTransform(translationByX: -bounds.origin.x, byY: -bounds.origin.y)
        path.transform(using: transform)

        let image = NSImage(size: path.bounds.size)
        image.lockFocus()
        path.fill()
        image.unlockFocus()
        return image
      }
    }
  }

  extension Snapshotting where Value == NSBezierPath, Format == String {
    /// A snapshot strategy for comparing bezier paths based on pixel equality.
    @available(macOS 11.0, *)
    @available(iOS 11.0, *)
    public static var elementsDescription: Snapshotting {
      return .elementsDescription(numberFormatter: defaultNumberFormatter)
    }

    /// A snapshot strategy for comparing bezier paths based on pixel equality.
    ///
    /// - Parameter numberFormatter: The number formatter used for formatting points.
    @available(macOS 11.0, *)
    @available(iOS 11.0, *)
    public static func elementsDescription(numberFormatter: NumberFormatter) -> Snapshotting {
      let namesByType: [NSBezierPath.ElementType: String] = [
        .moveTo: "MoveTo",
        .lineTo: "LineTo",
        .curveTo: "CurveTo",
        .closePath: "Close",
      ]

      let numberOfPointsByType: [NSBezierPath.ElementType: Int] = [
        .moveTo: 1,
        .lineTo: 1,
        .curveTo: 3,
        .closePath: 0,
      ]

      return SimplySnapshotting.lines.pullback { path in
        var string: String = ""

        var elementPoints = [CGPoint](repeating: .zero, count: 3)
        for elementIndex in 0..<path.elementCount {
          let elementType = path.element(at: elementIndex, associatedPoints: &elementPoints)
          let name = namesByType[elementType] ?? "Unknown"

          if elementType == .moveTo && !string.isEmpty {
            string += "\n"
          }

          string += name

          if let numberOfPoints = numberOfPointsByType[elementType] {
            let points = elementPoints[0..<numberOfPoints]
            string +=
              " "
              + points.map { point in
                let x = numberFormatter.string(from: point.x as NSNumber)!
                let y = numberFormatter.string(from: point.y as NSNumber)!
                return "(\(x), \(y))"
              }.joined(separator: " ")
          }

          string += "\n"
        }

        return string
      }
    }
  }

  private let defaultNumberFormatter: NumberFormatter = {
    let numberFormatter = NumberFormatter()
    numberFormatter.minimumFractionDigits = 1
    numberFormatter.maximumFractionDigits = 3
    return numberFormatter
  }()
#endif
