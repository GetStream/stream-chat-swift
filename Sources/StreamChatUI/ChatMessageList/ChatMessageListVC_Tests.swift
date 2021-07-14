//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageListVC_Tests: XCTestCase {
    var vc: ChatMessageListVC!
    var channelControllerMock: ChatChannelController_Mock<NoExtraData>!
    
    override func setUp() {
        super.setUp()
        vc = ChatMessageListVC()
        channelControllerMock = ChatChannelController_Mock.mock()
        vc.channelController = channelControllerMock
    }

    override func tearDown() {
        super.tearDown()
        vc = nil
        channelControllerMock = nil
    }
    
    func test_emptyAppearance() {
        channelControllerMock.simulateInitial(
            channel: .mock(cid: .unique),
            messages: [],
            state: .localDataFetched
        )
        AssertSnapshot(vc, isEmbeddedInNavigationController: true)
    }
    
    func test_defaultAppearance() {
        channelControllerMock.simulateInitial(
            channel: .mock(cid: .unique),
            messages: [
                .mock(id: .unique, cid: .unique, text: "One", author: .mock(id: .unique)),
                .mock(id: .unique, cid: .unique, text: "Two", author: .mock(id: .unique)),
                .mock(id: .unique, cid: .unique, text: "Three", author: .mock(id: .unique))
            ],
            state: .localDataFetched
        )
        AssertSnapshot(
            vc,
            isEmbeddedInNavigationController: true,
            variants: [.defaultLight]
        )
    }
    
    func test_deletedMessagesWithAttachmentsAppearance() {
        let imageAttachment = ChatMessageImageAttachment.mock(
            id: .unique,
            imageURL: TestImages.yoda.url
        ).asAnyAttachment
        
        let linkAttachment = ChatMessageLinkAttachment.mock(
            id: .unique,
            originalURL: URL(string: "https://www.yoda.com")!,
            assetURL: .unique(),
            previewURL: TestImages.yoda.url
        ).asAnyAttachment
        
        channelControllerMock.simulateInitial(
            channel: .mock(cid: .unique),
            messages: [
                .mock(id: .unique, cid: .unique, text: "One", author: .mock(id: .unique)),
                .mock(
                    id: .unique,
                    cid: .unique,
                    text: "Two",
                    author: .mock(id: .unique),
                    deletedAt: Date(timeIntervalSince1970: 800),
                    attachments: [imageAttachment],
                    isSentByCurrentUser: true,
                    attachmentCounts: [.image: 1]
                ),
                .mock(
                    id: .unique,
                    cid: .unique,
                    text: "Three",
                    author: .mock(id: .unique),
                    deletedAt: Date(timeIntervalSince1970: 1800),
                    attachments: [linkAttachment],
                    isSentByCurrentUser: true,
                    attachmentCounts: [.linkPreview: 1]
                )
            ],
            state: .localDataFetched
        )
        AssertSnapshot(
            vc,
            isEmbeddedInNavigationController: true,
            variants: [.defaultLight]
        )
    }

    func test_setUp_whenChannelControllerSynchronizeCompletes_shouldUpdateComposer() {
        class ComposerVC_Mock: ComposerVC {
            var updateContentCallCount = 0

            override func updateContent() {
                updateContentCallCount += 1
            }
        }

        var components = Components()
        components.messageComposerVC = ComposerVC_Mock.self
        vc.components = components

        vc.setUp()

        // When channel controller synchronize completes
        channelControllerMock.synchronize_completion?(nil)

        let composer = vc.messageComposerVC as! ComposerVC_Mock
        XCTAssertEqual(composer.updateContentCallCount, 1)
    }
}
