import InlineSnapshotTesting
import SwiftDiagnostics
import SwiftParser
import SwiftParserDiagnostics
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

public func assertMacroSnapshot(
  _ macros: [String: Macro.Type],
  of originalSource: () throws -> String,
  expandsTo expandedSource: (() -> String)? = nil,
  file: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  assertInlineSnapshot(
    of: try originalSource(),
    as: .macroExpansion(macros, file: file, line: line),
    syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
      trailingClosureLabel: "expandsTo",
      trailingClosureOffset: 1
    ),
    matches: expandedSource,
    file: file,
    function: function,
    line: line,
    column: column
  )
}

extension Snapshotting where Value == String, Format == String {
  public static func macroExpansion(
    _ macros: [String: Macro.Type],
    testModuleName: String = "TestModule",
    testFileName: String = "Test.swift",
    indentationWidth: Trivia? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> Self {
    Snapshotting<String, String>.lines.pullback { input in
      let origSourceFile = Parser.parse(source: input)
      let context = SwiftSyntaxMacroExpansion.BasicMacroExpansionContext(
        sourceFiles: [
          origSourceFile: .init(moduleName: testModuleName, fullFilePath: testFileName)
        ]
      )
      let indentationWidth = indentationWidth ?? Trivia(
        stringLiteral: String(
          SourceLocationConverter(fileName: "-", tree: origSourceFile).sourceLines
            .first(where: { $0.first?.isWhitespace == true && $0 != "\n" })?
            .prefix(while: { $0.isWhitespace })
            ?? "    "
        )
      )
      let expandedSourceFile = origSourceFile.expand(
        macros: macros,
        in: context,
        indentationWidth: indentationWidth
      )
      let converter = SourceLocationConverter(fileName: "-", tree: expandedSourceFile)
      let lines = converter.location(for: expandedSourceFile.endPosition).line
      let diagnostics = ParseDiagnosticsGenerator.diagnostics(for: expandedSourceFile)
        + context.diagnostics
      if !diagnostics.isEmpty {
        let s = DiagnosticsFormatter
          .annotatedSource(
            tree: expandedSourceFile,
            diags: diagnostics,
            contextSize: lines
          )
          .description
        return DiagnosticsFormatter
          .annotatedSource(
            tree: expandedSourceFile,
            diags: diagnostics,
            contextSize: lines
          )
          .description
          .replacingOccurrences(
            of: "\n +│ ( *(?:╰|├)─) error: ", with: "\n$1 🛑 ", options: .regularExpression
          )
          .replacingOccurrences(of: #"(^|\n) *\d* +│ "#, with: "$1", options: .regularExpression)
          .trimmingCharacters(in: .newlines)
      }
      return expandedSourceFile
        .description
        .trimmingCharacters(in: .newlines)
    }
  }
}
