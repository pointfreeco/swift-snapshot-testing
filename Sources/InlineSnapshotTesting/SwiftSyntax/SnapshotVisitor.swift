#if canImport(SwiftSyntax601)
import SwiftSyntax

final class SnapshotVisitor: SyntaxVisitor {

    let functionCallColumn: Int
    let functionCallLine: Int
    let sourceLocationConverter: SourceLocationConverter
    let closureDescriptor: SnapshotClosureDescriptor
    var trailingClosureLine: Int?

    init(
        functionCallLine: Int,
        functionCallColumn: Int,
        sourceLocationConverter: SourceLocationConverter,
        closureDescriptor: SnapshotClosureDescriptor
    ) {
        self.functionCallColumn = functionCallColumn
        self.functionCallLine = functionCallLine
        self.sourceLocationConverter = sourceLocationConverter
        self.closureDescriptor = closureDescriptor
        super.init(viewMode: .all)
    }

    override func visit(_ functionCallExpr: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let location = functionCallExpr.calledExpression.endLocation(
            converter: self.sourceLocationConverter,
            afterTrailingTrivia: true
        )

        guard
            self.functionCallLine == location.line,
            self.functionCallColumn == location.column
        else { return .visitChildren }

        let arguments = functionCallExpr.arguments
        let firstTrailingClosureOffset =
            arguments
            .enumerated()
            .reversed()
            .prefix(while: { $0.element.expression.is(ClosureExprSyntax.self) })
            .last?
            .offset ?? arguments.count

        let trailingClosureOffset =
            firstTrailingClosureOffset
            + self.closureDescriptor.trailingClosureOffset

        let centeredTrailingClosureOffset = trailingClosureOffset - arguments.count

        switch centeredTrailingClosureOffset {
        case ..<0:
            let index = arguments.index(arguments.startIndex, offsetBy: trailingClosureOffset)
            self.trailingClosureLine =
                arguments[index]
                .startLocation(converter: self.sourceLocationConverter)
                .line

        case 0:
            self.trailingClosureLine = functionCallExpr.trailingClosure.map {
                $0.startLocation(converter: self.sourceLocationConverter).line
            }

        case 1...:
            let index = functionCallExpr.additionalTrailingClosures.index(
                functionCallExpr.additionalTrailingClosures.startIndex,
                offsetBy: centeredTrailingClosureOffset - 1
            )
            if centeredTrailingClosureOffset - 1 < functionCallExpr.additionalTrailingClosures.count {
                self.trailingClosureLine =
                    functionCallExpr.additionalTrailingClosures[index]
                    .startLocation(converter: self.sourceLocationConverter)
                    .line
            }
        default:
            break
        }
        return .skipChildren
    }
}
#endif
