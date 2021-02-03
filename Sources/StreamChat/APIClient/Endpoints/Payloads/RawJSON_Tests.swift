//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class RawJSON_Tests: XCTestCase {
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
