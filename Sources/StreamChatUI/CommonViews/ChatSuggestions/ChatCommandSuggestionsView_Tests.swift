//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
@testable import StreamChat
@testable import StreamChatUI
import XCTest

class ChatCommandSuggestionsView_Tests: XCTestCase {
    /// Default width for the cell.
    private let defaultCellWidth: CGFloat = 250
    
    /// Default content of the view
    private let defaultCommand = Command(name: "Default", description: "", set: "", args: "[text]")
    
    func test_updateContent_whenCommandIsRecognized_commandIconImageIsUsed() {
        var config = UIConfig()
        config.images.commandIcons = [
            "yoda": TestImages.yoda.image
        ]
        config.images.messageComposerCommandFallback = TestImages.vader.image
        
        let view = ChatCommandSuggestionsView()
        view.uiConfig = config
        view.content = .init(name: "yoda", description: "", set: "", args: "[text]")
        
        view.updateContent()
        
        XCTAssertEqual(view.commandImageView.image, config.images.commandIcons["yoda"])
    }
    
    func test_updateContent_whenCommandIsNotRecognized_fallbackCommandImageIsUsed() {
        var config = UIConfig()
        config.images.commandIcons = [
            "yoda": TestImages.yoda.image
        ]
        config.images.messageComposerCommandFallback = TestImages.vader.image
        
        let view = ChatCommandSuggestionsView()
        view.uiConfig = config
        view.content = .init(name: "R2", description: "", set: "", args: "[text]")
        
        view.updateContent()
        
        XCTAssertEqual(view.commandImageView.image, config.images.messageComposerCommandFallback)
    }
    
    func test_defaultAppearance() {
        let view = makeView()
        view.content = defaultCommand
        AssertSnapshot(view)
    }

    func test_appearanceCustomization_usingUIConfig() {
        var config = UIConfig()
        config.images.commandIcons = [
            "default": TestImages.yoda.image
        ]
        
        let view = makeView()
        view.uiConfig = config
        view.content = defaultCommand
        
        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearanceCustomization_usingAppearanceHook() {
        class TestView: ChatCommandSuggestionsView {}
        TestView.defaultAppearance {
            $0.backgroundColor = .systemGray
            $0.commandNameSubtitleLabel.textColor = UIColor.white
            $0.commandNameLabel.textColor = UIColor.darkGray
        }
        
        let view = makeView(TestView.self)
        view.content = defaultCommand
        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatCommandSuggestionsView {
            override func setUpAppearance() {
                super.setUpAppearance()

                backgroundColor = .systemGray
                commandNameSubtitleLabel.textColor = UIColor.white
                commandNameLabel.textColor = UIColor.darkGray
            }
            
            override func setUpLayout() {
                super.setUpLayout()
                
                commandNameSubtitleLabel
                    .trailingAnchor
                    .constraint(equalTo: layoutMarginsGuide.trailingAnchor)
                    .isActive = true
            }
        }
        
        let view = makeView(TestView.self)
        view.content = defaultCommand
        AssertSnapshot(view, variants: [.defaultLight])
    }
    
    // MARK: - Factory Helper
    
    private func makeView(_ customView: ChatCommandSuggestionsView.Type? = nil) -> ChatCommandSuggestionsView {
        let view = customView != nil ? customView!.init() : ChatCommandSuggestionsView()
        view.widthAnchor.constraint(equalToConstant: defaultCellWidth).isActive = true
        return view.withoutAutoresizingMaskConstraints
    }
}
