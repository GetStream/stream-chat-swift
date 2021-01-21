//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class GuestUserTokenRequestPayload_Tests: XCTestCase {
    func test_guestUserTokenRequestPayload_isEncodedCorrectly_withDefaultExtraData() throws {
        let payload = GuestUserTokenRequestPayload(
            userId: .unique,
            name: .unique,
            imageURL: .unique(),
            extraData: NoExtraData.User.defaultValue
        )
        
        try verify(payload, isEncodedAs: ["id": payload.userId, "name": payload.name!, "image": payload.imageURL!])
    }
    
    func test_guestUserTokenRequestPayload_isEncodedCorrectly_withCustomExtraData() throws {
        let company = "getstream.io"
        let payload = GuestUserTokenRequestPayload(
            userId: .unique,
            name: .unique,
            imageURL: .unique(),
            extraData: TestExtraData(company: company)
        )
        
        try verify(
            payload,
            isEncodedAs: ["id": payload.userId, "name": payload.name!, "image": payload.imageURL!, "company": company]
        )
    }
    
    // MARK: - Private
    
    private func verify<ExtraData: UserExtraData>(
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

private struct TestExtraData: UserExtraData {
    static var defaultValue: TestExtraData = .init(company: "Stream")
    let company: String
}
