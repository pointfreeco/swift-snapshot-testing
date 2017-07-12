import Foundation
import Prelude

// Point-Free Foundation

func appendingPathComponent(_ component: String) -> (URL) -> URL {
  return { url in
    url.appendingPathComponent(component)
  }
}

func deletingLastPathComponent(_ url: URL) -> URL {
  return url.deletingLastPathComponent()
}

func deletingPathExtension(_ url: URL) -> URL {
  return url.deletingPathExtension()
}
