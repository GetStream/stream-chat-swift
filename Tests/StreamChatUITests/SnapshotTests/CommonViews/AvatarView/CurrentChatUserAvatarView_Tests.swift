//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class CurrentChatUserAvatarView_Tests: XCTestCase {
    var currentUserController: CurrentChatUserController_Mock!
    
    override func setUp() {
        super.setUp()
        currentUserController = .mock()
        currentUserController.currentUser_mock = .mock(id: "Yoda", imageURL: TestImages.yoda.url)
    }
    
    override func tearDown() {
        currentUserController = nil
        super.tearDown()
    }

    func test_emptyAppearance() {
        let view = CurrentChatUserAvatarView().withoutAutoresizingMaskConstraints
        
        var appearance = Appearance()
        appearance.colorPalette.background = .yellow
        view.appearance = appearance
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_defaultAppearance() {
        let view = CurrentChatUserAvatarView().withoutAutoresizingMaskConstraints
        view.components = .mock
        view.controller = currentUserController
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_customizationUsingSubclassing() {
        class TestView: CurrentChatUserAvatarView {
            override func setUpAppearance() {
                super.setUpAppearance()
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
        view.components = .mock
        
        // Snapshot empty appearance
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles, suffix: "empty")
        
        // Snapshot appearance with data
        view.controller = currentUserController
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
}
