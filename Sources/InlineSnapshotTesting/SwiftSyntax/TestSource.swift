#if canImport(SwiftSyntax509)
import SwiftSyntax

struct TestSource {
  let source: String
  let sourceFile: SourceFileSyntax
  let sourceLocationConverter: SourceLocationConverter
}
#endif
