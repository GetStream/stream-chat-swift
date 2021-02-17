//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class CurrentChatUserAvatarView_Tests: XCTestCase {
    var currentUserController: CurrentChatUserController_Mock<NoExtraData>!
    
    override func setUp() {
        super.setUp()
        currentUserController = .mock()
        currentUserController.currentUser_mock = .init(id: "Yoda", imageURL: TestImages.yoda.url)
    }
    
    override func tearDown() {
        currentUserController = nil
        super.tearDown()
    }

    func test_emptyAppearance() {
        let view = CurrentChatUserAvatarView().withoutAutoresizingMaskConstraints
        
        var config = UIConfig()
        config.colorPalette.background = .yellow
        view.uiConfig = config
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_defaultAppearance() {
        let view = CurrentChatUserAvatarView().withoutAutoresizingMaskConstraints
        view.controller = currentUserController
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_customizationUsingAppearanceHook() {
        class TestView: CurrentChatUserAvatarView {}
        TestView.defaultAppearance {
            $0.avatarView.backgroundColor = .blue
            $0.avatarView.imageView.backgroundColor = .brown
            $0.layer.borderWidth = 1
            $0.layer.borderColor = UIColor.green.cgColor
        }
        
        let view = TestView().withoutAutoresizingMaskConstraints
        
        // Snapshot empty appearance
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles, suffix: "empty")
        
        // Snapshot appearance with data
        view.controller = currentUserController
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_customizationUsingSubclassingHook() {
        class TestView: CurrentChatUserAvatarView {
            override func defaultAppearance() {
                avatarView.backgroundColor = .blue
                avatarView.imageView.backgroundColor = .brown
                layer.borderWidth = 1
                layer.borderColor = UIColor.green.cgColor
            }
            
            override func setUpLayout() {
                super.setUpLayout()
                
                NSLayoutConstraint.activate([
                    widthAnchor.constraint(equalToConstant: 50),
                    heightAnchor.constraint(equalToConstant: 50)
                ])
            }
        }
        
        let view = TestView().withoutAutoresizingMaskConstraints
        
        // Snapshot empty appearance
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles, suffix: "empty")
        
        // Snapshot appearance with data
        view.controller = currentUserController
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
}
