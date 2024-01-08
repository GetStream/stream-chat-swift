//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class Token_Tests: XCTestCase {
    func test_init() throws {
        let jwtToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIifQ.kFSLHRB5X62t0Zlc7nwczWUfsQMwfkpylC6jCUZ6Mc0"
        let token = try Token(rawValue: jwtToken)
        XCTAssertEqual(token.userId, "luke_skywalker")
        XCTAssertEqual(token.rawValue, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIifQ.kFSLHRB5X62t0Zlc7nwczWUfsQMwfkpylC6jCUZ6Mc0")
    }

    func test_init_whenNoUserId() {
        let jwtToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjoibHVrZV9za3l3YWxrZXIifQ.4d5JxYi_bcpvQJZix-goe534b_CsSM1dV-lEuq1L-1g"
        XCTAssertThrowsError(try Token(rawValue: jwtToken))
    }

    func test_expiration_whenNoExpProvided() throws {
        let jwtToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIifQ.kFSLHRB5X62t0Zlc7nwczWUfsQMwfkpylC6jCUZ6Mc0"
        let token = try Token(rawValue: jwtToken)
        XCTAssertEqual(token.expiration, nil)
        XCTAssertEqual(token.isExpired, false)
    }

    func test_expiration_whenExpired() throws {
        let jwtToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIiLCJleHAiOjI1NTMzODE1Mjl9.i1vpWu_9uV6DO7eIYuUokQxfMaTgh-Xq089wKLGw_sY"
        let token = try Token(rawValue: jwtToken)
        XCTAssertEqual(token.expiration?.timeIntervalSince1970, 2_553_381_529)
        XCTAssertEqual(token.isExpired, false)
    }

    func test_expiration_whenNotExpired() throws {
        let jwtToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIiLCJleHAiOjE2MDY2OTY3Mjl9.AkmNHUTKEFR8UP0W2HLFsS006Bi2IT7-fzMtJuI_J9Q"
        let token = try Token(rawValue: jwtToken)
        XCTAssertEqual(token.expiration?.timeIntervalSince1970, 1_606_696_729)
        XCTAssertEqual(token.isExpired, true)
    }

    func test_anonymousToken() {
        let token = Token.anonymous
        XCTAssertEqual(token.expiration, nil)
        XCTAssertEqual(token.isExpired, false)
        XCTAssertEqual(token.rawValue, "")
        XCTAssertTrue(!token.userId.isEmpty)
    }

    func test_developmentToken() {
        let expectedUserId = "luke_skywalker"
        let token = Token.development(userId: expectedUserId)
        XCTAssertEqual(token.expiration, nil)
        XCTAssertEqual(token.isExpired, false)
        XCTAssertEqual(token.rawValue, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIifQ==.devtoken")
        XCTAssertEqual(token.userId, expectedUserId)
    }
}
