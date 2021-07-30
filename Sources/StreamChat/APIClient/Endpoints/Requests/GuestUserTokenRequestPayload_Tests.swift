//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class GuestUserTokenRequestPayload_Tests: XCTestCase {
    func test_guestUserTokenRequestPayload_isEncodedCorrectly_withDefaultExtraData() throws {
        let payload = GuestUserTokenRequestPayload<NoExtraData>(
            userId: .unique,
            name: .unique,
            imageURL: .unique(),
            extraData: .defaultValue
        )
        
        try verify(payload, isEncodedAs: ["id": payload.userId, "name": payload.name!, "image": payload.imageURL!])
    }
    
    func test_guestUserTokenRequestPayload_isEncodedCorrectly_withCustomExtraData() throws {
        let company = "getstream.io"
        let payload = GuestUserTokenRequestPayload<TestExtraData>(
            userId: .unique,
            name: .unique,
            imageURL: .unique(),
            extraData: TestExtraData.User(company: company)
        )
        
        try verify(
            payload,
            isEncodedAs: ["id": payload.userId, "name": payload.name!, "image": payload.imageURL!, "company": company]
        )
    }
    
    // MARK: - Private
    
    private func verify(
        _ payload: GuestUserTokenRequestPayload<ExtraData>,
        isEncodedAs expected: [String: Any]
    ) throws {
        // Encode the user
        let data = try JSONEncoder.default.encode(payload)
        let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        // Assert encoding is correct
        AssertJSONEqual(json, expected)
    }
}

private struct TestExtraData: ExtraDataTypes {
    struct User: UserExtraData {
        static var defaultValue = Self(company: "Stream")
        let company: String
    }
}
