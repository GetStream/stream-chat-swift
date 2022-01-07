//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatMentionSuggestionView_Tests: XCTestCase {
    /// Default reference width for the cell. Not related to any screen size.
    private static var defaultCellWidth: CGFloat = 300

    private var chatUserOffline: ChatUser!
    private var chatUserOnline: ChatUser!
    private var chatUserNoName: ChatUser!

    override func setUp() {
        super.setUp()

        chatUserOffline = .mock(
            id: "darkside37",
            name: "Mr Vader",
            imageURL: TestImages.vader.url,
            isOnline: false
        )

        chatUserOnline = .mock(
            id: "darkside37",
            name: "Mr Vader",
            imageURL: TestImages.vader.url,
            isOnline: true
        )

        chatUserNoName = .mock(
            id: "yoda",
            imageURL: TestImages.yoda.url,
            isOnline: true
        )
    }

    func test_emptyAppearance() {
        let view = ChatMentionSuggestionView().withoutAutoresizingMaskConstraints
        view.widthAnchor.constraint(equalToConstant: Self.defaultCellWidth).isActive = true

        AssertSnapshot(view)
    }

    func test_defaultAppearance() {
        let view = ChatMentionSuggestionView().withoutAutoresizingMaskConstraints
        view.components = .mock
        view.widthAnchor.constraint(equalToConstant: Self.defaultCellWidth).isActive = true

        view.content = chatUserOnline
        AssertSnapshot(view, suffix: "online indicator visible")

        view.content = chatUserOffline
        AssertSnapshot(view)

        view.content = chatUserNoName
        AssertSnapshot(view, suffix: "user name not set")
    }

    func test_appearanceCustomization_usingComponents() {
        class RectIndicator: UIView & MaskProviding {
            override func didMoveToSuperview() {
                super.didMoveToSuperview()
                backgroundColor = .green
                widthAnchor.constraint(equalTo: heightAnchor, multiplier: 1).isActive = true
            }
            
            var maskingPath: CGPath? {
                UIBezierPath(rect: frame.insetBy(dx: -frame.width / 4, dy: -frame.height / 4)).cgPath
            }
        }

        class CustomAvatarView: ChatUserAvatarView {
            override func didMoveToSuperview() {
                super.didMoveToSuperview()
                backgroundColor = .green
                widthAnchor.constraint(equalTo: heightAnchor, multiplier: 1).isActive = true
            }
        }

        var components = Components.mock
        components.onlineIndicatorView = RectIndicator.self
        components.mentionAvatarView = CustomAvatarView.self

        let view = ChatMentionSuggestionView().withoutAutoresizingMaskConstraints
        view.widthAnchor.constraint(equalToConstant: Self.defaultCellWidth).isActive = true

        view.components = components
        view.content = chatUserOnline
        AssertSnapshot(view, suffix: "online indicator visible")

        view.content = chatUserOffline
        AssertSnapshot(view)

        view.content = chatUserNoName
        AssertSnapshot(view, suffix: "user name not set")
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatMentionSuggestionView {
            override func setUpAppearance() {
                super.setUpAppearance()
                backgroundColor = .systemPurple
                usernameLabel.textColor = .systemBlue
                usernameTagLabel.textColor = .darkGray
            }

            override func setUpLayout() {
                super.setUpLayout()

                NSLayoutConstraint.activate([
                    mentionSymbolImageView.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1),
                    mentionSymbolImageView.heightAnchor.constraint(equalTo: mentionSymbolImageView.widthAnchor),
                    mentionSymbolImageView.widthAnchor.constraint(equalToConstant: 30),
                    textContainer.leadingAnchor.constraint(
                        equalToSystemSpacingAfter: mentionSymbolImageView.trailingAnchor,
                        multiplier: 1
                    ),
                    avatarView.widthAnchor.constraint(equalToConstant: 30),
                    avatarView.heightAnchor.constraint(equalTo: avatarView.widthAnchor),
                    avatarView.leadingAnchor.constraint(equalTo: textContainer.trailingAnchor),
                    avatarView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
                ])
            }
        }

        let view = TestView().withoutAutoresizingMaskConstraints
        view.components = .mock
        view.widthAnchor.constraint(equalToConstant: Self.defaultCellWidth).isActive = true

        view.content = chatUserOnline
        AssertSnapshot(view, suffix: "with online indicator")

        // reset view to be online:
        view.content = chatUserOffline
        AssertSnapshot(view)

        view.content = chatUserNoName
        AssertSnapshot(view, suffix: "user name not set")
    }
}
