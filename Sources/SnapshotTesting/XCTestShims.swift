#if !os(Linux)
import XCTest

// NB: This is copied from swift-corelibs-xctest:
//     https://github.com/apple/swift-corelibs-xctest/commit/1c7fb283231ce53960a232aa7c771bb2d38dee62#diff-21f119a0f720851df3a6574724e3985bL162
// We need this because the SPM generated test manifest checks for `#if !os(macOS)`, which means the code
// runs on iOS, and these API's are not available on Darwin.

public typealias XCTestCaseClosure = (XCTestCase) throws -> Void
public typealias XCTestCaseEntry = (testCaseClass: XCTestCase.Type, allTests: [(String, XCTestCaseClosure)])

public func testCase<T: XCTestCase>(_ allTests: [(String, (T) -> () throws -> Void)]) -> XCTestCaseEntry {
  let tests: [(String, XCTestCaseClosure)] = allTests.map { ($0.0, test($0.1)) }
  return (T.self, tests)
}

private func test<T: XCTestCase>(_ testFunc: @escaping (T) -> () throws -> Void) -> XCTestCaseClosure {
  return { testCaseType in
    guard let testCase = testCaseType as? T else {
      fatalError("Attempt to invoke test on class \(T.self) with incompatible instance type \(type(of: testCaseType))")
    }

    try testFunc(testCase)()
  }
}
#endif
