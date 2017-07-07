import XCTest

@discardableResult
public func assertScreenshot(
  matching view: UIView,
  _ file: StaticString = #file,
  _ function: String = #function,
  _ line: UInt = #line)
  -> XCTAttachment? {

    let fileURL = URL(fileURLWithPath: String(describing: file))
    let screenshotsDirectoryURL = fileURL.deletingLastPathComponent()
      .appendingPathComponent("__Screenshots__")
    let fileManager = FileManager.default

    try! fileManager.createDirectory(
      at: screenshotsDirectoryURL,
      withIntermediateDirectories: true,
      attributes: nil
    )

    UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
    let context = UIGraphicsGetCurrentContext()!
    view.layer.render(in: context)
    let image = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    let data = UIImagePNGRepresentation(image)!

    let screenshotName = "\(fileURL.deletingPathExtension().lastPathComponent).\(function).png"
    let screenshotURL = URL(string: screenshotName, relativeTo: screenshotsDirectoryURL)!

    guard fileManager.fileExists(atPath: screenshotURL.path) else {
      try! data.write(to: screenshotURL)
      return nil
    }

    let existingData = try! Data(contentsOf: screenshotURL)

    guard existingData == data else {
      let imageDiff = diff(image, UIImage(data: existingData)!)
      let attachment = XCTAttachment(image: imageDiff)
      attachment.lifetime = .deleteOnSuccess

      let failedScreenshotUrl = URL.init(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(screenshotName)
      try! data.write(to: failedScreenshotUrl)

      let ksdiff = """
ksdiff "\(trimFileProtocol(screenshotURL))" "\(trimFileProtocol(failedScreenshotUrl))"
"""

      XCTAssert(
        false,
        "\(screenshotURL.debugDescription) does not match screenshot\n\n\(ksdiff)\n",
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

private func trimFileProtocol(_ url: URL) -> String {
  return String(url.absoluteString.suffix(url.absoluteString.count - 7))
}
