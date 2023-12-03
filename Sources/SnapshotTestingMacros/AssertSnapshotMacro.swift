import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

private enum AssertSnapShotParamList: String {
    init?(rawValue: String?) {
        if let rawValue, rawValue == "as" {
            self = .as
        }
        else if let rawValue, rawValue == "of" {
            self = .of
        }
        else if let rawValue, rawValue == "named" {
            self = .named
        } else {
            return nil
        }
    }
    case `as`, `of`, named
}

/// Implementation of the `AssertSnapshot` macro
///
///     #AssertSnapshotEqual(of: "Sample", as: .lines)
///
public struct AssertSnapshotEqualMacro: ExpressionMacro {
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> SwiftSyntax.ExprSyntax {
        guard !node.argumentList.children(viewMode: .all).isEmpty else {
            throw AssertSnapshotEqualError.message("AssertSnapshotEqual - Macro: the macro was not passed any arguments")
        }
        
        var ofArg: ExprSyntax?
        var asArg: ExprSyntax?
        var nameArg: ExprSyntax?
        
        for next in node.argumentList.children(viewMode: .all) {
            
            if AssertSnapShotParamList(rawValue: next.as(LabeledExprSyntax.self)?.label?.trimmed.text) == .of, let value = next.as(LabeledExprSyntax.self)?.expression {
                ofArg = value
            }
            
            if AssertSnapShotParamList(rawValue: next.as(LabeledExprSyntax.self)?.label?.trimmed.text) == .as, let value = next.as(LabeledExprSyntax.self)?.expression {
                asArg = value
            }
            
            if AssertSnapShotParamList(rawValue: next.as(LabeledExprSyntax.self)?.label?.trimmed.text) == .named,
               let value = next.as(LabeledExprSyntax.self)?.expression {
                nameArg = value
            }
        }

        if let nameArg, let ofArg, let asArg {
            return "assertSnapshot(of: \(ofArg), as: \(asArg), named: \(nameArg))"
        } else if let ofArg, let asArg {
            return "assertSnapshot(of: \(ofArg), as: \(asArg))"
        } else {
            context.diagnose(
                  Diagnostic(
                    node: Syntax(node),
                    message: AssertSnapshotEqualDiagnosticMessage(
                      message: "Failed to parse the incoming arg parameters (of:as:named:)",
                      diagnosticID: MessageID(domain: "#AssertSnapshotEqual - Macro", id: "error"),
                      severity: .error
                    )
                  )
                )
            throw AssertSnapshotEqualError.message("AssertSnapshotEqual - Macro: the macro does not have any of the expected arguments")
        }
    }
}

@main
struct AssertSnapshotEqualPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AssertSnapshotEqualMacro.self,
    ]
}

private struct AssertSnapshotEqualDiagnosticMessage: DiagnosticMessage, Error {
  let message: String
  let diagnosticID: MessageID
  let severity: DiagnosticSeverity
}

extension AssertSnapshotEqualDiagnosticMessage: FixItMessage {
  var fixItID: MessageID { diagnosticID }
}

private enum AssertSnapshotEqualError: Error, CustomStringConvertible {
  case message(String)

  var description: String {
    switch self {
    case .message(let text):
      return text
    }
  }
}
