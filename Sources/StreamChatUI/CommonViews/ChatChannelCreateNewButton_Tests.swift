//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatChannelCreateNewButton_Tests: XCTestCase {
    func test_defaultAppearance() {
        let view = ChatChannelCreateNewButton().withoutAutoresizingMaskConstraints
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_isHighlighted() {
        let view = ChatChannelCreateNewButton().withoutAutoresizingMaskConstraints
        view.isHighlighted = true
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_isDisabled() {
        let view = ChatChannelCreateNewButton().withoutAutoresizingMaskConstraints
        view.isEnabled = false
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_customizationUsingAppearanceHook() {
        class TestView: ChatChannelCreateNewButton {}
        TestView.defaultAppearance {
            $0.layer.borderWidth = 1
            $0.layer.borderColor = UIColor.green.cgColor
            $0.backgroundColor = .black
            $0.tintColor = .lightGray
        }
        
        let view = TestView().withoutAutoresizingMaskConstraints
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_customizationUsingSubclassingHook() {
        class TestView: ChatChannelCreateNewButton {
            override func defaultAppearance() {
                super.defaultAppearance()
                layer.borderWidth = 1
                layer.borderColor = UIColor.green.cgColor
                backgroundColor = .black
                tintColor = .lightGray
                setImage(uiConfig.images.close, for: .normal)
            }
            
            override func setUpLayout() {
                super.setUpLayout()
                
                NSLayoutConstraint.activate([
                    heightAnchor.constraint(equalToConstant: 20),
                    widthAnchor.constraint(equalToConstant: 20)
                ])
            }
        }
        
        let view = TestView().withoutAutoresizingMaskConstraints
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_customizationUsingUIConfig() {
        var config = UIConfig()
        config.images.newChat = config.images.close

        let view = ChatChannelCreateNewButton().withoutAutoresizingMaskConstraints
        view.uiConfig = config
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
}
