//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
        view.components = .mock
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_defaultAppearance() {
        let avatarViewOnline = ChatUserAvatarView().withoutAutoresizingMaskConstraints
        avatarViewOnline.addSizeConstraints()
        avatarViewOnline.components = .mock
        avatarViewOnline.content = user
        AssertSnapshot(avatarViewOnline, variants: .onlyUserInterfaceStyles, suffix: "with online indicator")

        let avatarViewOffline = ChatUserAvatarView().withoutAutoresizingMaskConstraints
        avatarViewOffline.addSizeConstraints()
        avatarViewOffline.components = .mock
        avatarViewOffline.content = .mock(id: .unique, imageURL: TestImages.yoda.url, isOnline: false)
        AssertSnapshot(avatarViewOffline, variants: .onlyUserInterfaceStyles, suffix: "without online indicator")
    }

    func test_appearanceCustomization_usingAppearanceAndComponents() {
        class RectIndicator: UIView, MaskProviding {
            override func didMoveToSuperview() {
                super.didMoveToSuperview()
                backgroundColor = .systemPink
                widthAnchor.constraint(equalTo: heightAnchor, multiplier: 1).isActive = true
            }
            
            var maskingPath: CGPath? {
                UIBezierPath(rect: frame.insetBy(dx: -frame.width / 4, dy: -frame.height / 4)).cgPath
            }
        }

        var appearance = Appearance()
        var components = Components.mock
        appearance.colorPalette.alternativeActiveTint = .brown
        components.onlineIndicatorView = RectIndicator.self

        let view = ChatUserAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.appearance = appearance
        view.components = components
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
        view.components = .mock
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
