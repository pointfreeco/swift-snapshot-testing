import XCTest

#if os(iOS)
import PDFKit

@available(iOS 11.0, macOS 10.13, *)
extension Diffing where Value == PDFDocument {
  /// A pixel-diffing strategy for PDFs which requires a 100% match.
  public static var rasterized: Diffing {
    return .rasterized()
  }

  /// A pixel-diffing strategy for PDFs that allows customizing how precise the matching must be.
  ///
  /// - Parameter precision: A value between 0 and 1, where 1 means the images must match 100% of their pixels.
  /// - Returns: A new diffing strategy.
  public static func rasterized(precision: Float = 1, scale: CGFloat? = nil) -> Diffing {
    return Diffing(
      toData: { $0.dataRepresentation()! },
      fromData: { PDFDocument(data: $0)! }
    ) { old, new in
      guard old != new else { return nil }

      let diffing: Diffing<Image> = .image(precision: precision, scale: scale)

      guard old.pageCount == new.pageCount else {
        let message = "Expected documents to have same number of pages"
        return (message, [])
      }

      for pageIndex in 0..<new.pageCount {
        let oldPage = old.page(at: pageIndex)!
        let newPage = new.page(at: pageIndex)!

        let oldImage = oldPage.thumbnail(of: oldPage.bounds(for: .mediaBox).size, for: .mediaBox)
        let newImage = newPage.thumbnail(of: newPage.bounds(for: .mediaBox).size, for: .mediaBox)

        if let difference = diffing.diff(oldImage, newImage) {
          return difference
        }
      }

      return nil
    }
  }
}

@available(iOS 11.0, macOS 10.13, *)
extension Snapshotting where Value == PDFDocument, Format == PDFDocument {
  static var rasterized: Snapshotting {
    return .rasterized()
  }

  static func rasterized(precision: Float = 1) -> Snapshotting {
    return .init(
      pathExtension: "pdf",
      diffing: .rasterized(precision: precision)
    )
  }
}
#endif
