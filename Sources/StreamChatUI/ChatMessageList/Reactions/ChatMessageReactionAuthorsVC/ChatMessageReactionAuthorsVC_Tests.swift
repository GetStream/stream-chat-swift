//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageReactionAuthorsVC_Tests: XCTestCase {
    var vc: ChatMessageReactionAuthorsVC!
    var messageControllerMock: ChatMessageController_Mock!

    let currentUserId = UserId.unique
    var defaultReactions: [ChatMessageReaction] {
        [
            ChatMessageReaction.mock(
                type: "like",
                author: .mock(id: currentUserId, imageURL: TestImages.chewbacca.url)
            ),
            ChatMessageReaction.mock(
                type: "wow",
                author: .mock(id: .unique, name: "Vader", imageURL: TestImages.vader.url)
            ),
            ChatMessageReaction.mock(
                type: "sad",
                author: .mock(id: .unique, name: "Baby Yoda", imageURL: TestImages.yoda.url)
            ),
            ChatMessageReaction.mock(
                type: "sad",
                author: .mock(id: .unique, name: "Vader", imageURL: TestImages.vader.url)
            ),
            ChatMessageReaction.mock(
                type: "sad",
                author: .mock(id: currentUserId, imageURL: TestImages.chewbacca.url)
            ),
            ChatMessageReaction.mock(
                type: "like",
                author: .mock(id: .unique, name: "Yoda", imageURL: TestImages.yoda.url)
            )
        ]
    }

    override func setUp() {
        super.setUp()

        vc = ChatMessageReactionAuthorsVC()
        vc.components = Components.mock

        messageControllerMock = ChatMessageController_Mock.mock(currentUserId: currentUserId)
        messageControllerMock.startObserversIfNeeded_mock = {}
        messageControllerMock.message_mock = .mock(
            id: .unique,
            cid: .unique,
            text: "Some text",
            author: .mock(id: .unique),
            reactionCounts: ["fake": defaultReactions.count]
        )
        messageControllerMock.reactions = defaultReactions
        vc.messageController = messageControllerMock
    }

    override func tearDown() {
        vc = nil
        messageControllerMock = nil

        super.tearDown()
    }

    func test_defaultAppearance() {
        AssertSnapshot(vc)
    }

    func test_defaultAppearance_whenOnlyOneReaction_shouldUseSingularLocalization() {
        messageControllerMock.message_mock = .mock(
            id: .unique,
            cid: .unique,
            text: "Some text",
            author: .mock(id: .unique),
            reactionCounts: ["like": 1]
        )
        messageControllerMock.reactions = [
            .mock(type: "like", author: .mock(id: .unique, imageURL: TestImages.vader.url))
        ]
        AssertSnapshot(vc, variants: [.defaultLight])
    }

    func test_defaultAppearance_shouldNotRenderUnavailableReactions() {
        messageControllerMock.message_mock = .mock(
            id: .unique,
            cid: .unique,
            text: "Some text",
            author: .mock(id: .unique),
            reactionCounts: ["fake": 1, "like": 1]
        )
        messageControllerMock.reactions = [
            .mock(type: "like", author: .mock(id: .unique, imageURL: TestImages.vader.url)),
            .mock(type: "fake", author: .mock(id: .unique, imageURL: TestImages.vader.url))
        ]
        AssertSnapshot(vc, variants: [.defaultLight])
    }

    func test_customAppearance() {
        // Test injecting a custom component works
        class CustomCell: ChatMessageReactionAuthorViewCell {
            override var authorAvatarSize: CGSize {
                .init(width: 80, height: 80)
            }

            override func setUpAppearance() {
                super.setUpAppearance()

                authorAvatarView.layer.borderColor = UIColor.systemBlue.cgColor
                authorAvatarView.layer.borderWidth = 2
            }
        }

        // Testing subclassing the component works
        class CustomVC: ChatMessageReactionAuthorsVC {
            override var reactionAuthorCellSize: CGSize {
                .init(width: 64, height: 95)
            }

            override func setUpAppearance() {
                super.setUpAppearance()

                topLabel.textColor = UIColor.systemBlue
            }
        }

        let vc = CustomVC()
        vc.messageController = messageControllerMock
        vc.components = Components.mock
        vc.components.reactionAuthorCell = CustomCell.self

        AssertSnapshot(vc, variants: [.defaultLight, .defaultDark])
    }
}
