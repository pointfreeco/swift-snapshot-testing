#if canImport(SwiftSyntax601)
import SwiftSyntax

struct TestSource {
    let source: String
    let sourceFile: SourceFileSyntax
    let sourceLocationConverter: SourceLocationConverter
}
#endif
