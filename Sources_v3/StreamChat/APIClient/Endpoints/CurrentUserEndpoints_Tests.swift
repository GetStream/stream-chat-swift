//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class CurrentUserEndpoints_Tests: XCTestCase {
    func test_updateCurrentUser_buildsCorrectly() {
        let payload: CurrentUserUpdateRequestBody<DefaultExtraData.User> = .init(
            id: "123",
            set: .init(name: "Luke Skywalker", imageURL: URL(string: "url")!, extraData: .init()),
            unset: [.image, .extraDataKey("custom_prop")]
        )
        
        let expectedEndpoint = Endpoint<CurrentUserUpdateResponse<DefaultExtraData.User>>(
            path: "users",
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["users": [payload]]
        )
        
        let endpoint: Endpoint<CurrentUserUpdateResponse> = .updateCurrentUser(payload: payload)
        
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
}
