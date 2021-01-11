//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class CurrentUserEndpoints_Tests: XCTestCase {
    func test_updateCurrentUser_buildsCorrectly() {
        let userId = "123"
        let payload: CurrentUserUpdateRequestBody<DefaultExtraData.User> = .init(
            id: userId,
            set: .init(name: "Nuno", imageURL: URL(string: "Fake")!, extraData: .init()),
            unset: [.image, .extraDataKey("custom_prop")]
        )
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "users",
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["users": [payload]]
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .updateCurrentUser(id: userId, payload: payload)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
}
