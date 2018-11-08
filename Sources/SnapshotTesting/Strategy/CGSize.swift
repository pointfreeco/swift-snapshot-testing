#if os(iOS) || os(macOS) || os(tvOS)
import CoreGraphics
#endif

public enum Orientation {
  case horizontal
  case vertical
}

extension CGSize {
  static func iPhoneSe(_ orientation: Orientation) -> CGSize {
    switch orientation {
    case .horizontal:
      return CGSize(width: 568, height: 320)
    case .vertical:
      return CGSize(width: 320, height: 568)
    }
  }

  static var iPhoneSe: CGSize {
    return .iPhoneSe(.vertical)
  }

  static func iPhone8(_ orientation: Orientation) -> CGSize {
    switch orientation {
    case .horizontal:
      return CGSize(width: 667, height: 375)
    case .vertical:
      return CGSize(width: 375, height: 667)
    }
  }

  static var iPhone8: CGSize {
    return .iPhone8(.vertical)
  }

  static func iPhone8Plus(_ orientation: Orientation) -> CGSize {
    switch orientation {
    case .horizontal:
      return CGSize(width: 736, height: 414)
    case .vertical:
      return CGSize(width: 414, height: 736)
    }
  }

  static var iPhone8Plus: CGSize {
    return .iPhone8Plus(.vertical)
  }

  static func iPadMini(_ orientation: Orientation) -> CGSize {
    switch orientation {
    case .horizontal:
      return CGSize(width: 1024, height: 768)
    case .vertical:
      return CGSize(width: 768, height: 1024)
    }
  }

  static var iPadMini: CGSize {
    return .iPadMini(.horizontal)
  }

  static func iPadPro10_5(_ orientation: Orientation) -> CGSize {
    switch orientation {
    case .horizontal:
      return CGSize(width: 1112, height: 834)
    case .vertical:
      return CGSize(width: 834, height: 1112)
    }
  }

  static var iPadPro10_5: CGSize {
    return .iPadPro10_5(.horizontal)
  }

  static func iPadPro12_9(_ orientation: Orientation) -> CGSize {
    switch orientation {
    case .horizontal:
      return CGSize(width: 1366, height: 1024)
    case .vertical:
      return CGSize(width: 1024, height: 1366)
    }
  }

  static var iPadPro12_9: CGSize {
    return .iPadPro12_9(.horizontal)
  }
}
