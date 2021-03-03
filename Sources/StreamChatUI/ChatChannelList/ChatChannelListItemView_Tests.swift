//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatChannelListItemView_Tests: XCTestCase {
    var content: (channel: ChatChannel?, currentUserId: UserId?)!
    
    override func setUp() {
        super.setUp()
        
        content = (
            channel: ChatChannel.mock(
                cid: .unique,
                name: "Channel 1",
                imageURL: TestImages.yoda.url,
                lastMessageAt: .init(timeIntervalSince1970: 1_611_951_526_000)
            ),
            currentUserId: .unique
        )
        
        NSTimeZone.default = TimeZone(secondsFromGMT: 0)!
    }
    
    func test_emptyState() {
        let view = ChatChannelListItemView().withoutAutoresizingMaskConstraints
        // Make sure the view is empty if there was content before.
        view.content = self.content
        view.content = (nil, nil)
        view.addSizeConstraints()
        AssertSnapshot(view)
    }
    
    func test_defaultAppearance() {
        let view = ChatChannelListItemView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.content = content
        AssertSnapshot(view)
    }
    
    func test_appearanceCustomization_usingUIConfig() {
        var config = UIConfig()
        config.font.bodyBold = .italicSystemFont(ofSize: 20)
        config.colorPalette.subtitleText = .cyan
        
        let view = ChatChannelListItemView().withoutAutoresizingMaskConstraints
        
        view.uiConfig = config
        view.addSizeConstraints()
        
        AssertSnapshot(view)
    }
        
    func test_appearanceCustomization_usingAppearanceHook() {
        class TestView: ChatChannelListItemView {}
        TestView.defaultAppearance {
            $0.subtitleLabel.font = .italicSystemFont(ofSize: 20)
            $0.backgroundColor = .cyan
        }
        
        let view = TestView().withoutAutoresizingMaskConstraints
        
        view.addSizeConstraints()
        
        view.content = content
        AssertSnapshot(view)
    }
    
    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatChannelListItemView {
            lazy var footnoteLabel = UILabel()
                .withoutAutoresizingMaskConstraints
                .withAdjustingFontForContentSizeCategory
            
            override func setUpAppearance() {
                titleLabel.textColor = .cyan
                subtitleLabel.textColor = .blue
                
                footnoteLabel.adjustsFontForContentSizeCategory = true
                footnoteLabel.font = .preferredFont(forTextStyle: .caption1)
            }
            
            override func setUpLayout() {
                super.setUpLayout()
                timestampLabel.isHidden = true
                
                addSubview(footnoteLabel)
                footnoteLabel.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor).isActive = true
                footnoteLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 8).isActive = true
                
                avatarView
                    .bottomAnchor
                    .constraint(equalTo: cellContentView.layoutMarginsGuide.bottomAnchor, constant: -20)
                    .isActive = true
            }
            
            override func updateContent() {
                super.updateContent()
                
                footnoteLabel.text = dateFormatter.string(from: content.channel!.lastMessageAt!)
            }
        }
        
        let view = TestView().withoutAutoresizingMaskConstraints
        
        view.addSizeConstraints()
        
        view.content = content
        AssertSnapshot(view)
    }
}

private extension ChatChannelListItemView {
    func addSizeConstraints() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 400)
        ])
    }
}
