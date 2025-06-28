import Foundation
import Testing

final class TestingSession: Sendable {

    static let shared = TestingSession()

    // MARK: - Private properties

    private let testCounter = TestCounter()
    private let forLoopCounter = TestCounter()

    private init() {}

    func functionPosition(
        fileID: StaticString,
        filePath: StaticString,
        function: String,
        line: UInt,
        column: UInt
    ) -> Int {
        testCounter(
            fileID: fileID,
            filePath: filePath,
            function: function,
            line: line,
            column: column
        )
    }

    func forLoop(
        fileID: StaticString,
        filePath: StaticString,
        function: String,
        line: UInt,
        column: UInt
    ) -> Int {
        forLoopCounter(
            fileID: fileID,
            filePath: filePath,
            function: function,
            line: line,
            column: column
        )
    }
}

extension TestingSession {

    fileprivate final class TestCounter: @unchecked Sendable {

        // MARK: - Private properties

        private let lock = NSLock()

        // MARK: - Unsafe properties

        private var _registry: [TestLocation: [TestPosition]] = [:]

        init() {}

        func callAsFunction(
            fileID: StaticString,
            filePath: StaticString,
            function: String,
            line: UInt,
            column: UInt
        ) -> Int {
            let key = TestLocation(
                fileID: fileID,
                filePath: filePath,
                function: function
            )

            let position = TestPosition(
                line: line,
                column: column
            )

            return lock.withLock {
                var items = _registry[key, default: []]

                if let index = items.firstIndex(of: position) {
                    return index + 1
                }

                items.append(position)
                _registry[key] = items
                return items.count
            }
        }
    }
}

extension TestingSession.TestCounter {

    fileprivate struct TestLocation: Hashable {

        private let fileID: String
        private let filePath: String
        private let function: String

        init(
            fileID: StaticString,
            filePath: StaticString,
            function: String
        ) {
            self.fileID = String(describing: fileID)
            self.filePath = String(describing: filePath)
            self.function = function
        }
    }

    fileprivate struct TestPosition: Hashable {

        private let line: UInt
        private let column: UInt

        init(line: UInt, column: UInt) {
            self.line = line
            self.column = column
        }
    }
}
