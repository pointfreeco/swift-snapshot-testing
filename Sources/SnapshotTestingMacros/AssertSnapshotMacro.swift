import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

struct AssertSnapShotParam {
    let param: AssertSnapShotParamList
    let node: LabeledExprListSyntax
    
    var value: ExprSyntax? {
        for next in node.children(viewMode: .all) {
            switch param {
            case .as:
                if next.as(LabeledExprSyntax.self)?.label?.trimmed.text == param.rawValue {
                    return next.as(LabeledExprSyntax.self)?.expression
                } else {
                   continue
                }
            case .of:
                if next.as(LabeledExprSyntax.self)?.label?.trimmed.text == param.rawValue {
                    return next.as(LabeledExprSyntax.self)?.expression
                } else {
                    continue
                }
            case .named:
                if next.as(LabeledExprSyntax.self)?.label?.trimmed.text == param.rawValue {
                    return next.as(LabeledExprSyntax.self)?.expression
                } else {
                    continue
                }
            }
        }
        return nil
    }
}
enum AssertSnapShotParamList: String {
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
        
        let ofArg = AssertSnapShotParam(param: .of, node: node.argumentList).value
        let asArg = AssertSnapShotParam(param: .as, node: node.argumentList).value
        let nameArg = AssertSnapShotParam(param: .named, node: node.argumentList).value

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
