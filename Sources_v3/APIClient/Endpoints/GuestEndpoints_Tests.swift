//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

final class GuestEndpoints_Tests: XCTestCase {
    func test_token_buildsCorrectly_withNoExtraData() {
        let extraData = NoExtraData()
        verifyEndpointBuildsCorrectly(with: extraData)
    }
    
    func test_token_buildsCorrectly_withDefaultExtraData() {
        let extraData = NameAndImageExtraData(name: .unique, imageURL: .unique())
        verifyEndpointBuildsCorrectly(with: extraData)
    }
    
    func test_token_buildsCorrectly_withCustomExtraData() {
        let extraData = TestExtraData(company: "getstream.io")
        verifyEndpointBuildsCorrectly(with: extraData)
    }
    
    // MARK: - Private
    
    private func verifyEndpointBuildsCorrectly<ExtraData: UserExtraData>(with extraData: ExtraData) {
        let payload = GuestUserTokenRequestPayload(userId: .unique, extraData: extraData)
        let expectedEndpoint = Endpoint<GuestUserTokenPayload<ExtraData>>(
            path: "guest",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["user": payload]
        )
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(.guestUserToken(userId: payload.userId, extraData: extraData)))
    }
}

private struct TestExtraData: UserExtraData {
    static var defaultValue: TestExtraData = .init(company: "Stream")
    let company: String
}
