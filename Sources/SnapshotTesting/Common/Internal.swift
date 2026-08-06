#if os(macOS)
  import Cocoa
  typealias Image = NSImage
  typealias ImageView = NSImageView
  typealias View = NSView
#elseif os(iOS) || os(tvOS) || os(visionOS)
  import UIKit
  typealias Image = UIImage
  typealias ImageView = UIImageView
  typealias View = UIView
#endif
