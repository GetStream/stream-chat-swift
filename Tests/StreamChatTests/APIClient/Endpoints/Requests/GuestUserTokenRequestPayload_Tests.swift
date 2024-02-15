//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class GuestUserTokenRequestPayload_Tests: XCTestCase {
    func test_guestUserTokenRequestPayload_isEncodedCorrectly_withDefaultExtraData() throws {
        let payload = GuestRequest(
            user: .init(id: .unique, custom: ["image": .string(.unique), "name": .string(.unique)])
        )

        try verify(payload, isEncodedAs: ["id": payload.user.id, "custom": payload.user.custom])
    }
}

extension GuestUserTokenRequestPayload_Tests {
    // MARK: - Private

    private func verify(
        _ payload: GuestRequest,
        isEncodedAs expected: [String: Any]
    ) throws {
        // Encode the user
        let data = try JSONEncoder.default.encode(payload)
        let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]

        // Assert encoding is correct
        AssertJSONEqual(json, expected)
    }
}
