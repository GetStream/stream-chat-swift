import XCTest
@testable import StreamChat

final class ChatChannelController_Tests: XCTestCase {
    var client: ChatClient!
    var controller: ChatChannelController!

    override func setUp() {
        super.setUp()
        client = ChatClient(config: ChatClientConfig(apiKeyString: "test_api_key"))
        controller = client.channelController(for: .init(cid: ChannelId(type: .messaging, id: "test_channel")))
    }

    override func tearDown() {
        client = nil
        controller = nil
        super.tearDown()
    }

    func test_maxMessagesLimit() {
        // Given
        let maxMessagesLimit = 10
        controller = client.channelController(for: .init(cid: ChannelId(type: .messaging, id: "test_channel")), maxMessagesLimit: maxMessagesLimit)

        // When
        let messages = controller.messages

        // Then
        XCTAssertEqual(messages.count, maxMessagesLimit)
    }

    func test_noMaxMessagesLimit() {
        // Given
        controller = client.channelController(for: .init(cid: ChannelId(type: .messaging, id: "test_channel")))

        // When
        let messages = controller.messages

        // Then
        XCTAssertGreaterThan(messages.count, 0)
    }
}
