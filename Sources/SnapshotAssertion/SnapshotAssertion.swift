import XCTest

@discardableResult
public func assertSnapshot(
  matching view: UIView,
  identifier: String? = nil,
  _ file: StaticString = #file,
  _ function: String = #function,
  _ line: UInt = #line)
  -> XCTAttachment? {

    let fileURL = URL(fileURLWithPath: String(describing: file))
    let snapshotsDirectoryURL = fileURL.deletingLastPathComponent()
      .appendingPathComponent("__Snapshots__")
    let fileManager = FileManager.default

    try! fileManager.createDirectory(
      at: snapshotsDirectoryURL,
      withIntermediateDirectories: true,
      attributes: nil
    )

    UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
    let context = UIGraphicsGetCurrentContext()!
    view.layer.render(in: context)
    let image = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    let data = UIImagePNGRepresentation(image)!

    let snapshotName = fileURL.deletingPathExtension().lastPathComponent
      + "_\(function.prefix(function.count - 2))"
      + (identifier.map({ "_" + $0 }) ?? "")
      + ".png"

    let snapshotURL = URL(string: snapshotName, relativeTo: snapshotsDirectoryURL)!

    guard fileManager.fileExists(atPath: snapshotURL.path) else {
      try! data.write(to: snapshotURL)
      return nil
    }

    let existingData = try! Data(contentsOf: snapshotURL)

    guard existingData == data else {
      let imageDiff = diff(image, UIImage(data: existingData)!)
      let attachment = XCTAttachment(image: imageDiff)
      attachment.lifetime = .deleteOnSuccess

      let failedSnapshotUrl = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(snapshotName)
      try! data.write(to: failedSnapshotUrl)

      let ksdiff = """
ksdiff "\(snapshotURL.path)" "\(failedSnapshotUrl.path)"
"""

      XCTAssert(
        false,
        """
\(snapshotURL.debugDescription) does not match snapshot

\(ksdiff)

""",
        file: file,
        line: line
      )

      return attachment
    }

    return nil
}

func diff(_ a: UIImage, _ b: UIImage) -> UIImage {
  let maxSize = CGSize(width: max(a.size.width, b.size.width), height: max(a.size.height, b.size.height))
  UIGraphicsBeginImageContextWithOptions(maxSize, true, 0)
  let context = UIGraphicsGetCurrentContext()!
  a.draw(in: CGRect(origin: .zero, size: a.size))
  context.setAlpha(0.5)
  context.beginTransparencyLayer(auxiliaryInfo: nil)
  b.draw(in: CGRect(origin: .zero, size: b.size))
  context.setBlendMode(.difference)
  context.setFillColor(UIColor.white.cgColor)
  context.fill(CGRect(origin: .zero, size: a.size))
  context.endTransparencyLayer()
  let image = UIGraphicsGetImageFromCurrentImageContext()!
  UIGraphicsEndImageContext()
  return image
}
