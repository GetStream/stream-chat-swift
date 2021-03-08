//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatMessageComposerSuggestionsViewController_Tests: XCTestCase {
    // We need to provide a size to the suggestions view since here we are testing the view in isolation,
    // and so we can't attach it to a bottomAnchorView. The test to verify the height calculation dependent
    // on the rows should be done in the parent view controller tests.
    private let defaultSuggestionsSize = CGSize(width: 360, height: 130)
    
    // MARK: - Mock Data
    
    private let commands: [Command] = [
        .init(name: "yodafy", description: "", set: "", args: "[text]"),
        .init(name: "vaderfy", description: "", set: "", args: "[@username] [text]")
    ]
    
    private let mentions: [_ChatUser<NoExtraData>] = [
        .mock(
            id: "vader",
            name: "Mr Vader",
            imageURL: TestImages.vader.url,
            isOnline: false
        ),
        .mock(
            id: "yoda",
            name: "Yoda",
            imageURL: TestImages.yoda.url,
            isOnline: true
        )
    ]
    
    var vc: ChatMessageComposerSuggestionsViewController!
    var config = UIConfig()
    
    override func setUp() {
        super.setUp()
        vc = ChatMessageComposerSuggestionsViewController()
        config.images.commandIcons["yodafy"] = TestImages.yoda.image
        config.images.messageComposerCommandFallback = TestImages.vader.image
        vc.uiConfig = config
    }
    
    override func tearDown() {
        super.tearDown()
        vc = nil
    }
    
    // MARK: - Commands Tests
    
    func test_commands_emptyAppearance() {
        vc.dataSource = ChatMessageComposerSuggestionsCommandDataSource(
            with: [],
            collectionView: vc.collectionView
        )
        
        AssertSnapshot(vc, variants: .onlyUserInterfaceStyles, screenSize: defaultSuggestionsSize)
    }

    func test_commands_defaultAppearance() {
        vc.dataSource = ChatMessageComposerSuggestionsCommandDataSource(
            with: commands,
            collectionView: vc.collectionView
        )
        
        AssertSnapshot(vc, screenSize: defaultSuggestionsSize)
    }

    func test_commands_appearanceCustomization_usingUIConfig() {
        class TestView: ChatMessageComposerSuggestionsCommandsHeaderView {
            override func setUpAppearance() {
                super.setUpAppearance()
                
                if #available(iOS 12.0, *), traitCollection.userInterfaceStyle == .dark {
                    headerLabel.textColor = .yellow
                } else {
                    headerLabel.textColor = .green
                }
            }
            
            override func setUpLayout() {
                super.setUpLayout()
                
                commandImageView.removeFromSuperview()
                headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15).isActive = true
            }
        }
        
        var config = self.config
        config.messageComposer.suggestionsHeaderView = TestView.self
        
        vc.uiConfig = config
        vc.dataSource = ChatMessageComposerSuggestionsCommandDataSource(
            with: commands,
            collectionView: vc.collectionView
        )
        
        AssertSnapshot(vc, variants: .onlyUserInterfaceStyles, screenSize: defaultSuggestionsSize)
    }

    func test_commands_appearanceCustomization_usingAppearanceHook() {
        class TestVC: ChatMessageComposerSuggestionsViewController {}
        TestVC.defaultAppearance {
            $0.collectionView.backgroundColor = .lightGray
            $0.collectionView.layer.cornerRadius = 0
        }
        
        let vc = TestVC()
        vc.uiConfig = config
        vc.dataSource = ChatMessageComposerSuggestionsCommandDataSource(
            with: commands,
            collectionView: vc.collectionView
        )
        
        AssertSnapshot(vc, variants: [.defaultLight], screenSize: defaultSuggestionsSize)
    }

    func test_commands_appearanceCustomization_usingSubclassing() {
        class TestVC: ChatMessageComposerSuggestionsViewController {
            override func setUpAppearance() {
                super.setUpAppearance()
                
                collectionView.backgroundColor = .lightGray
                collectionView.layer.cornerRadius = 20
            }
            
            override func setUpLayout() {
                super.setUpLayout()
                
                collectionView.leftAnchor.pin(equalTo: view.leftAnchor, constant: 15).isActive = true
                collectionView.rightAnchor.pin(equalTo: view.rightAnchor, constant: -15).isActive = true
            }
        }
        
        let vc = TestVC()
        vc.uiConfig = config
        vc.dataSource = ChatMessageComposerSuggestionsCommandDataSource(
            with: commands,
            collectionView: vc.collectionView
        )
        
        AssertSnapshot(vc, variants: [.defaultLight], screenSize: defaultSuggestionsSize)
    }
    
    // MARK: - Mentions Tests
    
    func test_mentions_emptyAppearance() {
        let searchController = ChatUserSearchController_Mock<NoExtraData>.mock()
        searchController.users_mock = []
        vc.dataSource = ChatMessageComposerSuggestionsMentionDataSource(
            collectionView: vc.collectionView,
            searchController: searchController
        )
        
        AssertSnapshot(vc, variants: .onlyUserInterfaceStyles, screenSize: defaultSuggestionsSize)
    }

    func test_mentions_defaultAppearance() {
        let searchController = ChatUserSearchController_Mock<NoExtraData>.mock()
        searchController.users_mock = mentions
        vc.dataSource = ChatMessageComposerSuggestionsMentionDataSource(
            collectionView: vc.collectionView,
            searchController: searchController
        )
        
        AssertSnapshot(vc, screenSize: defaultSuggestionsSize)
    }

    func test_mentions_appearanceCustomization_usingUIConfig() {
        class TestView: ChatMessageComposerMentionCellView {
            override func setUpAppearance() {
                super.setUpAppearance()
                usernameLabel.textColor = .orange
            }
            
            override func setUpLayout() {
                super.setUpLayout()
                
                let bottomSeparatorView = UIView().withoutAutoresizingMaskConstraints
                bottomSeparatorView.backgroundColor = .lightGray
                addSubview(bottomSeparatorView)
                bottomSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
                bottomSeparatorView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
                bottomSeparatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
                bottomSeparatorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            }
        }
        
        var config = self.config
        config.messageComposer.suggestionsMentionCellView = TestView.self

        vc.uiConfig = config
        let searchController = ChatUserSearchController_Mock<NoExtraData>.mock()
        searchController.users_mock = mentions
        vc.dataSource = ChatMessageComposerSuggestionsMentionDataSource(
            collectionView: vc.collectionView,
            searchController: searchController
        )
        
        AssertSnapshot(vc, variants: .onlyUserInterfaceStyles, screenSize: defaultSuggestionsSize)
    }

    func test_mentions_appearanceCustomization_usingAppearanceHook() {
        class TestView: ChatMessageComposerSuggestionsViewController {}
        TestView.defaultAppearance {
            $0.collectionView.layer.cornerRadius = 0
        }
        
        let vc = TestView()
        let searchController = ChatUserSearchController_Mock<NoExtraData>.mock()
        searchController.users_mock = mentions
        vc.dataSource = ChatMessageComposerSuggestionsMentionDataSource(
            collectionView: vc.collectionView,
            searchController: searchController
        )
        
        AssertSnapshot(vc, variants: [.defaultLight], screenSize: defaultSuggestionsSize)
    }

    func test_mentions_appearanceCustomization_usingSubclassing() {
        class TestView: ChatMessageComposerSuggestionsViewController {
            override func defaultAppearance() {
                super.defaultAppearance()

                collectionView.layer.cornerRadius = 0
            }
            
            override func setUpLayout() {
                super.setUpLayout()
                
                collectionView.leftAnchor.pin(equalTo: view.leftAnchor, constant: 15).isActive = true
                collectionView.rightAnchor.pin(equalTo: view.rightAnchor, constant: -15).isActive = true
            }
        }
        
        let vc = TestView()
        let searchController = ChatUserSearchController_Mock<NoExtraData>.mock()
        searchController.users_mock = mentions
        vc.dataSource = ChatMessageComposerSuggestionsMentionDataSource(
            collectionView: vc.collectionView,
            searchController: searchController
        )
        
        AssertSnapshot(vc, variants: [.defaultLight], screenSize: defaultSuggestionsSize)
    }
}
