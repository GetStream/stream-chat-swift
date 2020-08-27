//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

final class GuestUserTokenRequestPayload_Tests: XCTestCase {
    func test_guestUserTokenRequestPayload_isEncodedCorrectly_withDefaultExtraData() throws {
        let name = String.unique
        let imageURL = URL.unique()
        let payload = GuestUserTokenRequestPayload(
            userId: .unique,
            extraData: NameAndImageExtraData(name: name, imageURL: imageURL)
        )
        
        try verify(payload, isEncodedAs: ["id": payload.userId, "name": name, "image": imageURL])
    }
    
    func test_guestUserTokenRequestPayload_isEncodedCorrectly_withNoExtraData() throws {
        let payload = GuestUserTokenRequestPayload(userId: .unique, extraData: NoExtraData())
        
        try verify(payload, isEncodedAs: ["id": payload.userId])
    }
    
    func test_guestUserTokenRequestPayload_isEncodedCorrectly_withCustomExtraData() throws {
        let company = "getstream.io"
        let payload = GuestUserTokenRequestPayload(userId: .unique, extraData: TestExtraData(company: company))
        
        try verify(payload, isEncodedAs: ["id": payload.userId, "company": company])
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
