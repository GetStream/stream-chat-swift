//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatChannelAvatarView_Tests: XCTestCase {
    var currentUserId: UserId!
    var channel: ChatChannel!
    
    override func setUp() {
        super.setUp()
        currentUserId = .unique

        channel = ChatChannel.mockDMChannel(members: [
            .mock(id: currentUserId, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url, isOnline: true)
        ])
    }
    
    func test_emptyAppearance() {
        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        AssertSnapshot(view, variants: [.small])
    }

    func test_defaultAppearance_withDirectMessageChannel() {
        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.content = (channel, currentUserId)
        AssertSnapshot(view, variants: [.small], suffix: "with online indicator")

        // Reset the channel such that both members are offline
        channel = ChatChannel.mockDMChannel(members: [
            .mock(id: currentUserId, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url)
        ])

        view.content = (channel, currentUserId)
        AssertSnapshot(view, variants: [.small])
    }

    func test_defaultAppearance_withNonDMChannel() {
        // TODO: https://stream-io.atlassian.net/browse/CIS-652
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
        config.channelList.channelListItemSubviews.onlineIndicator = RectIndicator.self
        config.colorPalette.alternativeActiveTint = .brown
        config.colorPalette.lightBorder = .cyan

        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.uiConfig = config
        view.content = (channel, currentUserId)
        AssertSnapshot(view, variants: [.small])
    }

    func test_appearanceCustomization_usingAppearanceHook() {
        class TestView: ChatChannelAvatarView {}
        TestView.defaultAppearance {
            // Modify appearance
            $0.onlineIndicatorView.backgroundColor = .red
            $0.backgroundColor = .yellow

            // Modify layout
            NSLayoutConstraint.activate([
                $0.onlineIndicatorView.leftAnchor.constraint(equalTo: $0.leftAnchor),
                $0.onlineIndicatorView.bottomAnchor.constraint(equalTo: $0.bottomAnchor),
                $0.onlineIndicatorView.widthAnchor.constraint(equalToConstant: 20)
            ])
        }

        let view = TestView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.content = (channel, currentUserId)
        AssertSnapshot(view, variants: [.small])
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatChannelAvatarView {
            override func setUpAppearance() {
                onlineIndicatorView.backgroundColor = .red
                backgroundColor = .yellow
            }

            override func setUpLayout() {
                super.setUpLayout()
                NSLayoutConstraint.activate([
                    onlineIndicatorView.leftAnchor.constraint(equalTo: leftAnchor),
                    onlineIndicatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
                    onlineIndicatorView.widthAnchor.constraint(equalToConstant: 20)
                ])
            }
        }

        let view = TestView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.content = (channel, currentUserId)
        AssertSnapshot(view, variants: [.small])
    }
}

private extension ChatChannelAvatarView {
    /// `ChatChannelAvatarView` infers its size from the image but we want the size to be the same for all snapshots.
    func addSizeConstraints() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 50),
            widthAnchor.constraint(equalToConstant: 50)
        ])
    }
}
