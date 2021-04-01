//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatMessageComposerMentionCellView_Tests: XCTestCase {
    /// Default reference width for the cell. Not related to any screen size.
    private static var defaultCellWidth: CGFloat = 300

    private var chatUserOffline: _ChatUser<NoExtraData>!
    private var chatUserOnline: _ChatUser<NoExtraData>!
    private var chatUserNoName: _ChatUser<NoExtraData>!

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
        let view = ChatMessageComposerMentionCellView().withoutAutoresizingMaskConstraints
        view.widthAnchor.constraint(equalToConstant: Self.defaultCellWidth).isActive = true

        AssertSnapshot(view)
    }

    func test_defaultAppearance() {
        let view = ChatMessageComposerMentionCellView().withoutAutoresizingMaskConstraints
        view.widthAnchor.constraint(equalToConstant: Self.defaultCellWidth).isActive = true

        view.content = chatUserOnline
        AssertSnapshot(view, suffix: "online indicator visible")

        view.content = chatUserOffline
        AssertSnapshot(view)

        view.content = chatUserNoName
        AssertSnapshot(view, suffix: "user name not set")
    }

    func test_appearanceCustomization_usingUIConfig() {
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

        class CustomAvatarView: _ChatUserAvatarView<NoExtraData> {
            override func didMoveToSuperview() {
                super.didMoveToSuperview()
                backgroundColor = .green
                widthAnchor.constraint(equalTo: heightAnchor, multiplier: 1).isActive = true
            }
        }

        var config = UIConfig()
        config.onlineIndicatorView = RectIndicator.self
        config.messageComposer.mentionAvatarView = CustomAvatarView.self

        let view = ChatMessageComposerMentionCellView().withoutAutoresizingMaskConstraints
        view.widthAnchor.constraint(equalToConstant: Self.defaultCellWidth).isActive = true

        view.uiConfig = config
        view.content = chatUserOnline
        AssertSnapshot(view, suffix: "online indicator visible")

        view.content = chatUserOffline
        AssertSnapshot(view)

        view.content = chatUserNoName
        AssertSnapshot(view, suffix: "user name not set")
    }

    func test_appearanceCustomization_usingAppearanceHook() {
        class TestView: ChatMessageComposerMentionCellView {}
        TestView.defaultAppearance {
            // Modify appearance
            $0.backgroundColor = .systemPink
            $0.usernameLabel.textColor = .systemBlue
            $0.usernameTagLabel.textColor = .systemTeal
        }

        let view = TestView().withoutAutoresizingMaskConstraints
        view.widthAnchor.constraint(equalToConstant: Self.defaultCellWidth).isActive = true

        view.content = chatUserOnline
        AssertSnapshot(view, suffix: "online indicator visible")

        view.content = chatUserOffline
        AssertSnapshot(view)

        view.content = chatUserNoName
        AssertSnapshot(view, suffix: "user name not set")
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatMessageComposerMentionCellView {
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
                    textStackView.leadingAnchor.constraint(
                        equalToSystemSpacingAfter: mentionSymbolImageView.trailingAnchor,
                        multiplier: 1
                    ),
                    avatarView.widthAnchor.constraint(equalToConstant: 30),
                    avatarView.heightAnchor.constraint(equalTo: avatarView.widthAnchor),
                    avatarView.leadingAnchor.constraint(equalTo: textStackView.trailingAnchor),
                    avatarView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
                ])
            }
        }

        let view = TestView().withoutAutoresizingMaskConstraints
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
