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
        AssertSnapshot(view)
    }
    
    func test_isHighlighted() {
        let view = ChatChannelCreateNewButton().withoutAutoresizingMaskConstraints
        view.isHighlighted = true
        AssertSnapshot(view)
    }
    
    func test_isDisabled() {
        let view = ChatChannelCreateNewButton().withoutAutoresizingMaskConstraints
        view.isEnabled = false
        AssertSnapshot(view)
    }

    func test_customizationUsingAppearanceHook() {
        class TestView: ChatChannelCreateNewButton {}
        TestView.defaultAppearance {
            // Modify appearance
            $0.layer.borderWidth = 1
            $0.layer.borderColor = UIColor.green.cgColor
            $0.backgroundColor = .black
            $0.tintColor = .lightGray
            
            NSLayoutConstraint.activate([
                $0.heightAnchor.constraint(equalToConstant: 20),
                $0.widthAnchor.constraint(equalToConstant: 20)
            ])
        }
        
        let view = TestView().withoutAutoresizingMaskConstraints
        AssertSnapshot(view)
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
        AssertSnapshot(view)
    }
    
    func test_customizationUsingUIConfig() {
        var config = UIConfig()
        config.images.newChat = config.images.close

        let view = ChatChannelCreateNewButton().withoutAutoresizingMaskConstraints
        view.uiConfig = config
        AssertSnapshot(view)
    }
}
