//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import SwiftUI
import XCTest

class ChatChannelAvatarView_Tests: XCTestCase {
    var currentUserId: UserId!
    var channel: ChatChannel!
    
    override func setUp() {
        super.setUp()
        currentUserId = .unique

        channel = ChatChannel.mockDMChannel(lastActiveMembers: [
            .mock(id: currentUserId, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url, isOnline: true)
        ])
    }
    
    func test_emptyAppearance() {
        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_defaultAppearance_withDirectMessageChannel() {
        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.content = (channel: channel, currentUserId: currentUserId)
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles, suffix: "with online indicator")

        // Reset the channel such that both members are offline
        channel = ChatChannel.mockDMChannel(lastActiveMembers: [
            .mock(id: currentUserId, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url)
        ])

        view.content = (channel: channel, currentUserId: currentUserId)
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
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
        config.onlineIndicatorView = RectIndicator.self
        config.colorPalette.alternativeActiveTint = .brown
        config.colorPalette.lightBorder = .cyan

        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.uiConfig = config
        view.content = (channel: channel, currentUserId: currentUserId)
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearanceCustomization_usingAppearanceHook() {
        class TestView: ChatChannelAvatarView {}
        TestView.defaultAppearance {
            $0.presenceAvatarView.onlineIndicatorView.backgroundColor = .red
            $0.backgroundColor = .yellow
        }

        let view = TestView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.content = (channel: channel, currentUserId: currentUserId)
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatChannelAvatarView {
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
        view.content = (channel: channel, currentUserId: currentUserId)
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    @available(iOS 13.0, *)
    func test_wrappedChatChannelAvatarViewInSwiftUI() {
        struct CustomView: View {
            @EnvironmentObject var uiConfig: UIConfig.ObservableObject
            let content: (channel: _ChatChannel<NoExtraData>?, currentUserId: UserId?)
            
            var body: some View {
                uiConfig.channelList.itemSubviews.avatarView.asView(content)
                    .frame(width: 50, height: 50)
            }
        }
        
        final class CustomAvatarView: ChatChannelAvatarView {
            override func setUpAppearance() {
                super.setUpAppearance()
                
                presenceAvatarView.avatarView.imageView.backgroundColor = .red
            }
        }
        
        let channel = ChatChannel.mock(cid: .unique)
        
        var config = UIConfig()
        config.channelList.itemSubviews.avatarView = CustomAvatarView.self
        let view = CustomView(content: (channel, .unique))
            .environmentObject(config.asObservableObject)
        
        AssertSnapshot(view)
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
