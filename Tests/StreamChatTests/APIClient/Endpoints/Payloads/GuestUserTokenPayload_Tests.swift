//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class GuestUserTokenPayload_Tests: XCTestCase {
    let guestUserDefaultExtraDataJSON = XCTestCase.mockData(fromFile: "GuestUser+DefaultExtraData")
    let guestUserCustomExtraDataJSON = XCTestCase.mockData(fromFile: "GuestUser+CustomExtraData")
    let guestUserInvalidTokenJSON = XCTestCase.mockData(fromFile: "GuestUser+InvalidToken")

    func test_guestUserDefaultExtraData_isSerialized() throws {
        let payload = try JSONDecoder.default.decode(
            GuestUserTokenPayload.self,
            from: guestUserDefaultExtraDataJSON
        )

        XCTAssertEqual(
            payload.token,
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYnJva2VuLXdhdGVyZmFsbC01In0.QPeAmdig1KbLwYInW8hwi0XML3kO1M6HH76k4IU0sDg"
        )
        XCTAssertNotNil(payload.user)
        XCTAssertEqual(payload.user.id, "broken-waterfall-5")
        XCTAssertFalse(payload.user.isBanned)
        XCTAssertEqual(payload.user.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.user.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertEqual(payload.user.name, "Broken Waterfall")
        XCTAssertEqual(
            payload.user.imageURL,
            URL(string: "https://getstream.io/random_svg/?id=broken-waterfall-5&amp;name=Broken+waterfall")!
        )
        XCTAssertEqual(payload.user.role, .guest)
        XCTAssertTrue(payload.user.isOnline)
    }
    
    func test_guestUserCustomExtraData_isSerialized() throws {
        let payload = try JSONDecoder.default.decode(GuestUserTokenPayload.self, from: guestUserCustomExtraDataJSON)

        XCTAssertEqual(
            payload.token,
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYnJva2VuLXdhdGVyZmFsbC01In0.QPeAmdig1KbLwYInW8hwi0XML3kO1M6HH76k4IU0sDg"
        )
        XCTAssertNotNil(payload.user)
        XCTAssertEqual(payload.user.id, "broken-waterfall-5")
        XCTAssertFalse(payload.user.isBanned)
        XCTAssertEqual(payload.user.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.user.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertEqual(payload.user.extraData, ["company": .string("getstream.io")])
        XCTAssertEqual(payload.user.role, .guest)
        XCTAssertTrue(payload.user.isOnline)
    }

    func test_guestUserWithInvalidToken_isFailedToBeSerialized() throws {
        XCTAssertThrowsError(
            try JSONDecoder.default.decode(GuestUserTokenPayload.self, from: guestUserInvalidTokenJSON)
        ) { error in
            XCTAssertTrue(error is ClientError.InvalidToken)
        }
    }
}
