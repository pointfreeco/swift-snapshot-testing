import SnapshotTestingCustomDump
import XCTSnapshot

#if canImport(XCTest)
import XCTest

class CustomDumpTests: XCTestCase {

    override func invokeTest() {
        withTestingEnvironment(
            record: .failed,
            diffTool: .ksdiff,
            platform: ""
        ) {
            super.invokeTest()
        }
    }

    func testAny() throws {
        struct User { let id: Int, name: String, bio: String }
        let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
        try assert(
            of: user,
            as: .customDump
        )
    }

    func testRecursion() throws {
        try withTestingEnvironment {
            final class Father {
                var child: Child?
                init(_ child: Child? = nil) { self.child = child }
            }
            final class Child {
                let father: Father
                init(_ father: Father) {
                    self.father = father
                    father.child = self
                }
            }
            let father = Father()
            let child = Child(father)
            try assert(of: father, as: .customDump)
            try assert(of: child, as: .customDump)
        }
    }

    func testAnySnapshotStringConvertible() throws {
        try assert(of: "a" as Character, as: .customDump, named: "character")
        try assert(of: Data("Hello, world!".utf8), as: .customDump, named: "data")
        try assert(of: Date(timeIntervalSinceReferenceDate: 0), as: .customDump, named: "date")
        try assert(of: NSObject(), as: .customDump, named: "nsobject")
        try assert(of: "Hello, world!", as: .customDump, named: "string")
        try assert(of: "Hello, world!".dropLast(8), as: .customDump, named: "substring")
        try assert(of: URL(string: "https://www.pointfree.co")!, as: .customDump, named: "url")
    }

    func testDeterministicDictionaryAndSetSnapshots() throws {
        struct Person: Hashable { let name: String }
        struct DictionarySetContainer { let dict: [String: Int], set: Set<Person> }
        let set = DictionarySetContainer(
            dict: ["c": 3, "a": 1, "b": 2],
            set: [.init(name: "Brandon"), .init(name: "Stephen")]
        )
        try assert(of: set, as: .customDump)
    }

    func testMultipleSnapshots() throws {
        try assert(of: [1], as: .customDump)
        try assert(of: [1, 2], as: .customDump)
    }

    func testNamedAssertion() throws {
        struct User { let id: Int, name: String, bio: String }
        let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
        try assert(of: user, as: .customDump, named: "named")
    }
}
#endif
