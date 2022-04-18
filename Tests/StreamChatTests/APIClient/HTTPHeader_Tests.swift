//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class HTTPHeader_Tests: XCTestCase {
    func test_anonymousStreamAuth() {
        // Create the header.
        let header: HTTPHeader = .anonymousStreamAuth

        // Assert header has correct values.
        XCTAssertEqual(header.key.rawValue, "Stream-Auth-Type")
        XCTAssertEqual(header.value, "anonymous")
    }

    func test_jwtStreamAuth() {
        // Create the header.
        let header: HTTPHeader = .jwtStreamAuth

        // Assert header has correct values.
        XCTAssertEqual(header.key.rawValue, "Stream-Auth-Type")
        XCTAssertEqual(header.value, "jwt")
    }

    func test_authorization() {
        // Create a token.
        let token: String = .unique

        // Create the header.
        let header: HTTPHeader = .authorization(token)

        // Assert header has correct values.
        XCTAssertEqual(header.key.rawValue, "Authorization")
        XCTAssertEqual(header.value, token)
    }

    func test_setHTTPHeaders() {
        // Create a request.
        var request = URLRequest(url: .unique())

        // Create list of initial headers.
        let oldHeaders: [HTTPHeader] = [
            .anonymousStreamAuth,
            .authorization(.unique)
        ]

        // Set initial headers.
        for header in oldHeaders {
            request.setHTTPHeaders(header)
        }

        // Create list of new headers.
        let newHeaders: [HTTPHeader] = [
            .jwtStreamAuth,
            .authorization(.unique)
        ]

        // Set new headers.
        for header in newHeaders {
            request.setHTTPHeaders(header)
        }

        // Assert old headers are replaced with new headers.
        for header in newHeaders {
            let value = request.value(forHTTPHeaderField: header.key.rawValue)
            XCTAssertEqual(value, header.value)
        }
    }

    func test_addHTTPHeaders() throws {
        // Create a request.
        var request = URLRequest(url: .unique())

        // Create a header key.
        let headerKey: HTTPHeader.Key = .authorization

        // Create a list of headers with the same key.
        let headers: [HTTPHeader] = [
            .init(key: headerKey, value: .unique),
            .init(key: headerKey, value: .unique)
        ]

        // Add headers with the same key.
        for header in headers {
            request.addHTTPHeaders(header)
        }

        // Assert the resulting header value contains all
        let value = try XCTUnwrap(request.value(forHTTPHeaderField: headerKey.rawValue))
        XCTAssertEqual(
            Set(value.split(separator: ",").map(String.init)),
            Set(headers.map(\.value))
        )
    }
}
