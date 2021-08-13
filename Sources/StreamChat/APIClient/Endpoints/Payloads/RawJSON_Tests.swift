//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class RawJSON_Tests: XCTestCase {
    func test_valueEncoding() throws {
        struct test {
            var value: RawJSON
            var expected: String
        }

        let tests = [
            test.init(value: .dictionary(["k": .bool(false)]), expected: "{\"k\": false}"),
            test.init(value: .dictionary(["k": .bool(true)]), expected: "{\"k\": true}"),
            test.init(value: .dictionary(["k": .double(3.14)]), expected: "{\"k\": 3.14}"),
            test.init(value: .dictionary(["k": .integer(3)]), expected: "{\"k\": 3}"),
            test.init(value: .dictionary(["k": .string("asd")]), expected: "{\"k\": \"asd\"}")
        ]
        
        for test in tests {
            let encoded = try JSONEncoder.stream.encode(test.value)
            AssertJSONEqual(encoded, test.expected.data(using: .utf8)!)
        }
    }

    func test_valueDecoding() throws {
        struct test {
            var value: String
            var expected: RawJSON
        }

        let tests = [
            test.init(value: "{\"k\": false}", expected: .dictionary(["k": .bool(false)])),
            test.init(value: "{\"k\": true}", expected: .dictionary(["k": .bool(true)])),
            test.init(value: "{\"k\": 3.14}", expected: .dictionary(["k": .double(3.14)])),
            test.init(value: "{\"k\": 3}", expected: .dictionary(["k": .integer(3)])),
            test.init(value: "{\"k\": \"asd\"}", expected: .dictionary(["k": .string("asd")]))
        ]
        
        for test in tests {
            let rawJSON = try? JSONDecoder.stream.decode(RawJSON.self, from: test.value.data(using: .utf8)!)
            XCTAssertEqual(rawJSON, test.expected)
        }
    }

    func test_rawJSON_encodedAndDecoded() throws {
        let attachmentType: String = "route"
        let routeId: Int = 123
        let routeType: String = "hike"
        let routeMapURL = URL(string: "https://getstream.io/routeMap.jpg")!

        let data: Data = """
            {   "type": "\(attachmentType)",
                "route": {
                    "id": \(routeId), "type": "\(routeType)"
                },
                "routeMapURL": "\(routeMapURL.absoluteString)"
            }
        """.data(using: .utf8)!

        var rawJSON: RawJSON?

        rawJSON = try? JSONDecoder().decode(RawJSON.self, from: data)

        let encoded = try JSONEncoder().encode(rawJSON)

        struct RouteAttachment: Decodable {
            let type: String
            let route: Route
            let routeMapURL: URL
        }

        struct Route: Decodable {
            let id: Int
            let type: String
        }

        let decoded = try JSONDecoder().decode(RouteAttachment.self, from: encoded)

        XCTAssertEqual(decoded.type, attachmentType)
        XCTAssertEqual(decoded.routeMapURL, routeMapURL)
        XCTAssertEqual(decoded.route.type, routeType)
        XCTAssertEqual(decoded.route.id, routeId)
    }
}
