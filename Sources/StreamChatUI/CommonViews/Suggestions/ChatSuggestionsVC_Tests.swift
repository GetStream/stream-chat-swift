//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatSuggestionsVC_Tests: XCTestCase {
    // We need to provide a size to the suggestions view since here we are testing the view in isolation,
    // and so we can't attach it to a bottomAnchorView. The test to verify the height calculation dependent
    // on the rows should be done in the parent view controller tests.
    private let defaultSuggestionsSize = CGSize(width: 360, height: 130)
    
    // MARK: - Mock Data
    
    private let commands: [Command] = [
        .init(name: "yodafy", description: "", set: "", args: "[text]"),
        .init(name: "vaderfy", description: "", set: "", args: "[@username] [text]")
    ]
    
    private let mentions: [ChatUser] = [
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
    
    var vc: ChatSuggestionsVC!
    var appearance = Appearance()
    var components: Components = .mock
    
    override func setUp() {
        super.setUp()
        vc = ChatSuggestionsVC()
        appearance.images.commandIcons["yodafy"] = TestImages.yoda.image
        appearance.images.commandFallback = TestImages.vader.image
        vc.appearance = appearance
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

    func test_commands_appearanceCustomization_usingComponents() {
        class TestView: ChatSuggestionsHeaderView {
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
        
        var components = self.components
        components.suggestionsHeaderView = TestView.self
        
        vc.components = components
        vc.dataSource = ChatMessageComposerSuggestionsCommandDataSource(
            with: commands,
            collectionView: vc.collectionView
        )

        AssertSnapshot(vc, variants: .onlyUserInterfaceStyles, screenSize: defaultSuggestionsSize)
    }

    func test_commands_appearanceCustomization_usingSubclassing() {
        class TestVC: ChatSuggestionsVC {
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
        vc.appearance = appearance
        vc.components = components
        vc.dataSource = ChatMessageComposerSuggestionsCommandDataSource(
            with: commands,
            collectionView: vc.collectionView
        )
        
        AssertSnapshot(vc, variants: [.defaultLight], screenSize: defaultSuggestionsSize)
    }
    
    // MARK: - Mentions Tests
    
    func test_mentions_emptyAppearance() {
        let searchController = ChatUserSearchController_Mock.mock()
        searchController.users_mock = []
        vc.dataSource = ChatMessageComposerSuggestionsMentionDataSource(
            collectionView: vc.collectionView,
            searchController: searchController
        )
        
        AssertSnapshot(vc, variants: .onlyUserInterfaceStyles, screenSize: defaultSuggestionsSize)
    }

    func test_mentions_defaultAppearance() {
        let searchController = ChatUserSearchController_Mock.mock()
        searchController.users_mock = mentions
        vc.dataSource = ChatMessageComposerSuggestionsMentionDataSource(
            collectionView: vc.collectionView,
            searchController: searchController,
            usersCache: mentions
        )
        vc.components = .mock
        
        AssertSnapshot(vc, screenSize: defaultSuggestionsSize)
    }

    func test_mentions_appearanceCustomization_usingComponents() {
        class TestView: ChatMentionSuggestionView {
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
        
        var components = self.components
        components.suggestionsMentionView = TestView.self

        vc.components = components
        let searchController = ChatUserSearchController_Mock.mock()
        searchController.users_mock = mentions
        vc.dataSource = ChatMessageComposerSuggestionsMentionDataSource(
            collectionView: vc.collectionView,
            searchController: searchController,
            usersCache: mentions
        )
        
        AssertSnapshot(vc, variants: .onlyUserInterfaceStyles, screenSize: defaultSuggestionsSize)
    }

    func test_mentions_appearanceCustomization_usingSubclassing() {
        class TestView: ChatSuggestionsVC {
            override func setUpAppearance() {
                super.setUpAppearance()
                collectionView.layer.cornerRadius = 0
            }
            
            override func setUpLayout() {
                super.setUpLayout()
                
                collectionView.leftAnchor.pin(equalTo: view.leftAnchor, constant: 15).isActive = true
                collectionView.rightAnchor.pin(equalTo: view.rightAnchor, constant: -15).isActive = true
            }
        }
        
        let vc = TestView()
        let searchController = ChatUserSearchController_Mock.mock()
        searchController.users_mock = mentions
        vc.components = .mock
        vc.dataSource = ChatMessageComposerSuggestionsMentionDataSource(
            collectionView: vc.collectionView,
            searchController: searchController,
            usersCache: mentions
        )
        
        AssertSnapshot(vc, variants: [.defaultLight], screenSize: defaultSuggestionsSize)
    }
}
