//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
import XCTest

@available(iOS 13.0, *)
final class UIViewController_Extensions_Tests: iOS13TestCase {
    func test_navigationItemProperties_arePopulatedToParent() {
        let vc = UIViewController()

        let appearance = UINavigationBarAppearance()
        let barButton = UIBarButtonItem()
        let searchController = UISearchController()
        let titleView = UIView()
        let title = "Title"
        let prompt = "Prompt"

        let leftBarButtonItems = [
            barButton,
            barButton
        ]
        let rightBarButtonItems = [
            barButton,
            barButton
        ]

        // Set navigationItem properties of VC
        setupNavigationItem(
            vc.navigationItem,
            backButtonDisplayMode: .minimal,
            backBarButtonItem: barButton,
            backButtonTitle: title,
            compactAppearance: appearance,
            hidesSearchBarWhenScrolling: true,
            largeTitleDisplayMode: .always,
            hidesBackButton: false,
            leftBarButtonItems: leftBarButtonItems,
            leftItemsSupplementBackButton: false,
            prompt: prompt,
            rightBarButtonItems: rightBarButtonItems,
            scrollEdgeAppearance: appearance,
            searchController: searchController,
            standardAppearance: appearance,
            titleView: titleView
        )
        vc.title = title

        // Setup parent VC with default values of navigationItem properties
        let parentVC = UIViewController()
        let parentNavItem = parentVC.navigationItem

        vc.setupParentNavigation(parent: parentVC)

        // Assert navigationItem properties are propagated to parent
        if #available(iOS 14.0, *) {
            XCTAssertEqual(parentNavItem.backButtonDisplayMode, .minimal)
        }

        XCTAssertEqual(parentNavItem.backBarButtonItem, barButton)
        XCTAssertEqual(parentNavItem.backButtonTitle, title)
        XCTAssertEqual(parentNavItem.compactAppearance, vc.navigationItem.compactAppearance)
        XCTAssertTrue(parentNavItem.hidesSearchBarWhenScrolling)
        XCTAssertEqual(parentNavItem.largeTitleDisplayMode, .always)
        XCTAssertFalse(parentNavItem.hidesBackButton)
        XCTAssertEqual(parentNavItem.leftBarButtonItems, leftBarButtonItems)
        XCTAssertFalse(parentNavItem.leftItemsSupplementBackButton)
        XCTAssertEqual(parentNavItem.prompt, prompt)
        XCTAssertEqual(parentNavItem.rightBarButtonItem, barButton)
        XCTAssertEqual(parentNavItem.scrollEdgeAppearance, appearance)
        XCTAssertEqual(parentNavItem.searchController, searchController)
        XCTAssertEqual(parentNavItem.standardAppearance, appearance)
        XCTAssertEqual(parentNavItem.title, title)
        XCTAssertEqual(parentNavItem.titleView, titleView)
    }
    
    func test_parentNavigationItemProperties_arePreserved() {
        let vc = UIViewController()

        let parentAppearance = UINavigationBarAppearance()
        let parentSearchController = UISearchController()
        let parentTitleView = UIView()
        let parentTitle = "Parent Title"
        let parentPrompt = "Parent Prompt"

        let parentBarButton = UIBarButtonItem()
        let parentLeftBarButtonItems = [
            parentBarButton,
            parentBarButton
        ]
        let parentRightBarButtonItems = [
            parentBarButton,
            parentBarButton
        ]

        // Setup navigationItem properties of parent VC
        let parentVC = UIViewController()
        let parentNavItem = parentVC.navigationItem

        setupNavigationItem(
            parentNavItem,
            backButtonDisplayMode: .generic,
            backBarButtonItem: parentBarButton,
            backButtonTitle: parentTitle,
            compactAppearance: parentAppearance,
            hidesSearchBarWhenScrolling: false,
            largeTitleDisplayMode: .never,
            hidesBackButton: true,
            leftBarButtonItems: parentLeftBarButtonItems,
            leftItemsSupplementBackButton: true,
            prompt: parentPrompt,
            rightBarButtonItems: parentRightBarButtonItems,
            scrollEdgeAppearance: parentAppearance,
            searchController: parentSearchController,
            standardAppearance: parentAppearance,
            titleView: parentTitleView
        )
        parentVC.title = parentTitle

        vc.setupParentNavigation(parent: parentVC)

        // Assert navigationItem properties of parent are preserved
        if #available(iOS 14.0, *) {
            XCTAssertEqual(parentNavItem.backButtonDisplayMode, .generic)
        }

        XCTAssertEqual(parentNavItem.backBarButtonItem, parentBarButton)
        XCTAssertEqual(parentNavItem.backButtonTitle, parentTitle)
        XCTAssertEqual(parentNavItem.compactAppearance, parentAppearance)
        XCTAssertFalse(parentNavItem.hidesSearchBarWhenScrolling)
        XCTAssertEqual(parentNavItem.largeTitleDisplayMode, .never)
        XCTAssertTrue(parentNavItem.hidesBackButton)
        XCTAssertEqual(parentNavItem.leftBarButtonItems, parentLeftBarButtonItems)
        XCTAssertTrue(parentNavItem.leftItemsSupplementBackButton)
        XCTAssertEqual(parentNavItem.prompt, parentPrompt)
        XCTAssertEqual(parentNavItem.rightBarButtonItem, parentBarButton)
        XCTAssertEqual(parentNavItem.scrollEdgeAppearance, parentAppearance)
        XCTAssertEqual(parentNavItem.searchController, parentSearchController)
        XCTAssertEqual(parentNavItem.standardAppearance, parentAppearance)
        XCTAssertEqual(parentNavItem.title, parentTitle)
        XCTAssertEqual(parentNavItem.titleView, parentTitleView)
    }

    /// Helper function to setup `UINavigationItem` properties.
    private func setupNavigationItem(
        _ navigationItem: UINavigationItem,
        backButtonDisplayMode: UINavigationItem.BackButtonDisplayMode = .default,
        backBarButtonItem: UIBarButtonItem? = nil,
        backButtonTitle: String? = nil,
        compactAppearance: UINavigationBarAppearance? = nil,
        hidesSearchBarWhenScrolling: Bool = true,
        largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode = .automatic,
        hidesBackButton: Bool = false,
        leftBarButtonItems: [UIBarButtonItem]? = nil,
        leftItemsSupplementBackButton: Bool = false,
        prompt: String? = nil,
        rightBarButtonItems: [UIBarButtonItem]? = nil,
        scrollEdgeAppearance: UINavigationBarAppearance? = nil,
        searchController: UISearchController? = nil,
        standardAppearance: UINavigationBarAppearance? = nil,
        titleView: UIView? = nil
    ) {
        if #available(iOS 14.0, *) {
            navigationItem.backButtonDisplayMode = backButtonDisplayMode
        }
        
        navigationItem.backBarButtonItem = backBarButtonItem
        navigationItem.backButtonTitle = backButtonTitle
        navigationItem.compactAppearance = compactAppearance
        navigationItem.hidesSearchBarWhenScrolling = hidesSearchBarWhenScrolling
        navigationItem.largeTitleDisplayMode = largeTitleDisplayMode
        navigationItem.hidesBackButton = hidesBackButton
        navigationItem.leftBarButtonItems = leftBarButtonItems
        navigationItem.leftItemsSupplementBackButton = leftItemsSupplementBackButton
        navigationItem.prompt = prompt
        navigationItem.rightBarButtonItems = rightBarButtonItems
        navigationItem.scrollEdgeAppearance = scrollEdgeAppearance
        navigationItem.searchController = searchController
        navigationItem.standardAppearance = standardAppearance
        navigationItem.titleView = titleView
    }
}
