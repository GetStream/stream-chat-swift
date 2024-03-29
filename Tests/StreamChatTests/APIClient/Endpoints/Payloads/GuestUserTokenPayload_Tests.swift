//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class GuestUserTokenPayload_Tests: XCTestCase {
    let guestUserDefaultExtraDataJSON = XCTestCase.mockData(fromJSONFile: "GuestUser+DefaultExtraData")
    let guestUserCustomExtraDataJSON = XCTestCase.mockData(fromJSONFile: "GuestUser+CustomExtraData")
    let guestUserInvalidTokenJSON = XCTestCase.mockData(fromJSONFile: "GuestUser+InvalidToken")

    func test_guestUserDefaultExtraData_isSerialized() throws {
        let payload = try JSONDecoder.default.decode(
            CreateGuestResponse.self,
            from: guestUserDefaultExtraDataJSON
        )

        XCTAssertEqual(
            payload.accessToken,
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYnJva2VuLXdhdGVyZmFsbC01In0.QPeAmdig1KbLwYInW8hwi0XML3kO1M6HH76k4IU0sDg"
        )
        XCTAssertNotNil(payload.user)
        XCTAssertEqual(payload.user.id, "broken-waterfall-5")
        XCTAssert(payload.user.banned == false)
        XCTAssertEqual(payload.user.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.user.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
//        XCTAssertEqual(payload.user.name, "Broken Waterfall")
//        XCTAssertEqual(
//            payload.user.imageURL,
//            URL(string: "https://getstream.io/random_svg/?id=broken-waterfall-5&amp;name=Broken+waterfall")!
//        )
        XCTAssertEqual(payload.user.role, UserRole.guest.rawValue)
        XCTAssert(payload.user.online == true)
    }

    func test_guestUserCustomExtraData_isSerialized() throws {
        let payload = try JSONDecoder.default.decode(CreateGuestResponse.self, from: guestUserCustomExtraDataJSON)

        XCTAssertEqual(
            payload.accessToken,
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYnJva2VuLXdhdGVyZmFsbC01In0.QPeAmdig1KbLwYInW8hwi0XML3kO1M6HH76k4IU0sDg"
        )
        XCTAssertNotNil(payload.user)
        XCTAssertEqual(payload.user.id, "broken-waterfall-5")
        XCTAssert(payload.user.banned == false)
        XCTAssertEqual(payload.user.createdAt, "2019-12-12T15:33:46.488935Z".toDate())
        XCTAssertEqual(payload.user.updatedAt, "2020-06-10T14:11:29.946106Z".toDate())
        XCTAssertEqual(payload.user.custom, ["company": .string("getstream.io")])
        XCTAssertEqual(payload.user.role, UserRole.guest.rawValue)
        XCTAssert(payload.user.online == true)
    }
}
