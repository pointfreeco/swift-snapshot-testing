@preconcurrency import Foundation
import XCSnapshotTesting

#if canImport(XCTest)
@preconcurrency import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class FoundationTests: BaseTestCase {

    @available(macOS 10.13, tvOS 11.0, *)
    func testAnyAsJson() throws {
        struct User: Encodable { let id: Int, name: String, bio: String }
        let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")

        let data = try JSONEncoder().encode(user)
        let any = try JSONSerialization.jsonObject(with: data, options: [])

        try assert(of: any, as: .json)
    }

    func testCaseIterable() throws {
        enum Direction: String, CaseIterable {
            case up, down, left, right
            var rotatedLeft: Direction {
                switch self {
                case .up: return .left
                case .down: return .right
                case .left: return .down
                case .right: return .up
                }
            }
        }

        try assert(
            of: { $0.rotatedLeft },
            as: SyncSnapshot<Direction, StringBytes>.func(into: .description)
        )
    }

    func testData() async throws {
        let data = Data([0xDE, 0xAD, 0xBE, 0xEF])

        try assert(of: data, as: .data)
    }

    func testEncodable() throws {
        struct User: Encodable { let id: Int, name: String, bio: String }
        let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")

        if #available(iOS 11.0, macOS 10.13, tvOS 11.0, *) {
            try assert(of: user, as: .json)
        }
        try assert(of: user, as: .plist)
    }

    func testURLRequest() throws {
        var get = URLRequest(url: URL(string: "https://www.pointfree.co/")!)
        get.addValue("pf_session={}", forHTTPHeaderField: "Cookie")
        get.addValue("text/html", forHTTPHeaderField: "Accept")
        get.addValue("application/json", forHTTPHeaderField: "Content-Type")
        try assert(of: get, as: .raw, named: "get")
        try assert(of: get, as: .curl, named: "get-curl")

        var getWithQuery = URLRequest(
            url: URL(string: "https://www.pointfree.co?key_2=value_2&key_1=value_1&key_3=value_3")!
        )
        getWithQuery.addValue("pf_session={}", forHTTPHeaderField: "Cookie")
        getWithQuery.addValue("text/html", forHTTPHeaderField: "Accept")
        getWithQuery.addValue("application/json", forHTTPHeaderField: "Content-Type")
        try assert(
            of: getWithQuery,
            as: .raw,
            named: "get-with-query"
        )
        try assert(
            of: getWithQuery,
            as: .curl,
            named: "get-with-query-curl"
        )

        var post = URLRequest(url: URL(string: "https://www.pointfree.co/subscribe")!)
        post.httpMethod = "POST"
        post.addValue("pf_session={\"user_id\":\"0\"}", forHTTPHeaderField: "Cookie")
        post.addValue("text/html", forHTTPHeaderField: "Accept")
        post.httpBody = Data("pricing[billing]=monthly&pricing[lane]=individual".utf8)
        try assert(
            of: post,
            as: .raw,
            named: "post"
        )
        try assert(
            of: post,
            as: .curl,
            named: "post-curl"
        )

        var postWithJSON = URLRequest(
            url: URL(string: "http://dummy.restapiexample.com/api/v1/create")!
        )
        postWithJSON.httpMethod = "POST"
        postWithJSON.addValue("application/json", forHTTPHeaderField: "Content-Type")
        postWithJSON.addValue("application/json", forHTTPHeaderField: "Accept")
        postWithJSON.httpBody = Data(
            "{\"name\":\"tammy134235345235\", \"salary\":0, \"age\":\"tammy133\"}".utf8
        )
        try assert(
            of: postWithJSON,
            as: .raw,
            named: "post-with-json"
        )
        try assert(
            of: postWithJSON,
            as: .curl,
            named: "post-with-json-curl"
        )

        var head = URLRequest(url: URL(string: "https://www.pointfree.co/")!)
        head.httpMethod = "HEAD"
        head.addValue("pf_session={}", forHTTPHeaderField: "Cookie")
        try assert(of: head, as: .raw, named: "head")
        try assert(of: head, as: .curl, named: "head-curl")

        post = URLRequest(url: URL(string: "https://www.pointfree.co/subscribe")!)
        post.httpMethod = "POST"
        post.addValue("pf_session={\"user_id\":\"0\"}", forHTTPHeaderField: "Cookie")
        post.addValue("application/json", forHTTPHeaderField: "Accept")
        post.httpBody = Data(
            """
            {"pricing": {"lane": "individual","billing": "monthly"}}
            """.utf8
        )
    }
}
#endif
