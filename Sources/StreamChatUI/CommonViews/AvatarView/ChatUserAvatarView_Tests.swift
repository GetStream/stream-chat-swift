//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatUserAvatarView_Tests: XCTestCase {
    var user: ChatUser!

    override func setUp() {
        super.setUp()
        user = .mock(id: .unique, imageURL: TestImages.yoda.url, isOnline: true)
    }

    func test_emptyAppearance() {
        let view = ChatUserAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_defaultAppearance() {
        let avatarViewOnline = ChatUserAvatarView().withoutAutoresizingMaskConstraints
        avatarViewOnline.addSizeConstraints()
        avatarViewOnline.content = user
        AssertSnapshot(avatarViewOnline, variants: .onlyUserInterfaceStyles, suffix: "with online indicator")

        let avatarViewOffline = ChatUserAvatarView().withoutAutoresizingMaskConstraints
        avatarViewOffline.addSizeConstraints()
        avatarViewOffline.content = .mock(id: .unique, imageURL: TestImages.yoda.url, isOnline: false)
        AssertSnapshot(avatarViewOffline, variants: .onlyUserInterfaceStyles, suffix: "without online indicator")
    }

    func test_appearanceCustomization_usingUIConfig() {
        class RectIndicator: UIView {
            override func didMoveToSuperview() {
                super.didMoveToSuperview()
                backgroundColor = .systemPink
                widthAnchor.constraint(equalTo: heightAnchor, multiplier: 1).isActive = true
            }
        }

        var config = UIConfig()
        config.onlineIndicatorView = RectIndicator.self
        config.colorPalette.alternativeActiveTint = .brown
        config.colorPalette.lightBorder = .cyan

        let view = ChatUserAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.uiConfig = config
        view.content = user
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearanceCustomization_usingAppearanceHook() {
        class TestView: ChatUserAvatarView {}
        TestView.defaultAppearance {
            $0.presenceAvatarView.onlineIndicatorView.backgroundColor = .red
            $0.backgroundColor = .yellow
        }

        let view = TestView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.content = user
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatUserAvatarView {
            override func setUpAppearance() {
                presenceAvatarView.onlineIndicatorView.backgroundColor = .red
                backgroundColor = .yellow
            }

            override func setUpLayout() {
                super.setUpLayout()
                NSLayoutConstraint.activate([
                    presenceAvatarView.onlineIndicatorView.leftAnchor.constraint(equalTo: leftAnchor),
                    presenceAvatarView.onlineIndicatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
                    presenceAvatarView.onlineIndicatorView.widthAnchor.constraint(equalToConstant: 20),
                    presenceAvatarView.onlineIndicatorView.heightAnchor.constraint(equalToConstant: 20)
                ])
            }
        }

        let view = TestView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.content = user
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
}

private extension ChatUserAvatarView {
    /// `ChatUserAvatarView` infers its size from the image but we want the size to be the same for all snapshots.
    func addSizeConstraints() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 50),
            widthAnchor.constraint(equalToConstant: 50)
        ])
    }
}
