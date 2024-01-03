//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChatClientFactory_Tests: XCTestCase {
    func test_makeUrlSessionConfiguration_whenCustomHeadersProvided() {
        let config = ChatClientConfig(apiKeyString: "example")
        config.urlSessionConfiguration.httpAdditionalHeaders = ["Custom": "Example"]
        let factory = ChatClientFactory(config: config, environment: .mock)

        let urlSessionConfiguration = factory.makeUrlSessionConfiguration()

        XCTAssertNotNil(urlSessionConfiguration.httpAdditionalHeaders?["Custom"])
        XCTAssertNotNil(urlSessionConfiguration.httpAdditionalHeaders?["X-Stream-Client"])
    }

    func test_makeUrlSessionConfiguration_whenCustomHeadersCollide() {
        let config = ChatClientConfig(apiKeyString: "example")
        config.urlSessionConfiguration.httpAdditionalHeaders = ["X-Stream-Client": "Fake"]
        let factory = ChatClientFactory(config: config, environment: .mock)

        let urlSessionConfiguration = factory.makeUrlSessionConfiguration()

        XCTAssertNotNil(urlSessionConfiguration.httpAdditionalHeaders?["X-Stream-Client"])
        XCTAssertTrue(urlSessionConfiguration.httpAdditionalHeaders?["X-Stream-Client"] as? String != "Fake")
    }
}
