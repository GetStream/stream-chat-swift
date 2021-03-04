//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatChannelSwipeableListItemView_Tests: XCTestCase {

    func test_defaultAppearance() {
        let view = ChatChannelSwipeableListItemView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        
        // Simulate view moving to superview to have view initialized.
        view.executeLifecycleMethods()
        
        // Buttons are revealed after swipe gesture so we need to simulate it to check the buttons.
        view.swipeOpen()
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_appearanceCustomization_usingUIConfig() {
        class TestView: UIButton {
            override init(frame: CGRect) {
                super.init(frame: frame)
                layer.borderWidth = 2
                layer.borderColor = UIColor.red.cgColor
                tintColor = UIColor.orange
            }

            required init?(coder: NSCoder) {
                super.init(coder: coder)
            }
        }

        var config = UIConfig()
        config.channelList.swipeableItemSubviews.deleteButton = TestView.self
        
        let view = ChatChannelSwipeableListItemView().withoutAutoresizingMaskConstraints
        
        view.uiConfig = config
        view.addSizeConstraints()

        // Simulate view moving to superview to have view initialized.
        view.executeLifecycleMethods()
        
        // Buttons are revealed after swipe gesture so we need to simulate it to check the buttons.
        view.swipeOpen()
    
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_appearanceCustomization_usingAppearanceHook() {
        class TestView: ChatChannelSwipeableListItemView {}
        TestView.defaultAppearance {
            $0.deleteButton.tintColor = .cyan
        }

        let view = TestView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        
        // Simulate view moving to superview to have view initialized.
        view.executeLifecycleMethods()
        
        // Buttons are revealed after swipe gesture so we need to simulate it to check the buttons.
        view.swipeOpen()

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatChannelSwipeableListItemView {
            override func setUpAppearance() {
                deleteButton.tintColor = .cyan
            }

            override func setUpLayout() {
                super.setUpLayout()
                
                let button = UIButton()
                button.setImage(TestImages.yoda.image, for: .normal)
                button.imageView?.contentMode = .scaleAspectFit
                
                NSLayoutConstraint.activate([
                    button.heightAnchor.constraint(equalToConstant: 50),
                    button.widthAnchor.constraint(equalToConstant: 50)
                ])
                
                actionButtonStack.addArrangedSubview(button)
            }
        }

        let view = TestView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()

        // Simulate view moving to superview to have view initialized.
        view.executeLifecycleMethods()
        
        // Buttons are revealed after swipe gesture so we need to simulate it to check the buttons.
        view.swipeOpen()
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_deleteButtonHandler() {
        let view = ChatChannelSwipeableListItemView()
        
        var deleteButtonTapped = false
        view.deleteButtonAction = {
            deleteButtonTapped = true
        }
        
        // Trigger lifecycle methods for setting up the target-action for `deleteButton`.
        view.executeLifecycleMethods()
        
        view.deleteButton.simulateEvent(.touchUpInside)
        
        XCTAssert(deleteButtonTapped)
    }

    func test_ItemView_usesCorrectUIConfigTypes_whenCustomTypesDefined() {
        // Create default ChatChannelListVC which has everything default from `UIConfig`
        let itemView = ChatChannelSwipeableListItemView()

        // Create new config to set custom types...
        var customConfig = UIConfig()

        customConfig.channelList.swipeableItemSubviews.actionButtonStack = TestStackView.self
        customConfig.channelList.swipeableItemSubviews.deleteButton = TestButton.self

        itemView.uiConfig = customConfig

        XCTAssert(itemView.actionButtonStack is TestStackView)
        XCTAssert(itemView.deleteButton is TestButton)
    }
    
}

private extension ChatChannelSwipeableListItemView {
    func swipeOpen() {
        trailingConstraint?.constant = 100
    }
    
    func addSizeConstraints() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 50),
            widthAnchor.constraint(equalToConstant: 150)
        ])
    }
}
