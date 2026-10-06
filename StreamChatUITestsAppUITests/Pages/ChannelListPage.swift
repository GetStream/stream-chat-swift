//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import XCTest

enum ChannelListPage {
    static var userAvatar: XCUIElement { app.otherElements["CurrentChatUserAvatarView"] }

    static var loadingView: XCUIElement { app.descendants(matching: .any)["ChatChannelListLoadingView"].firstMatch }

    static var cells: XCUIElementQuery {
        app.cells.matching(NSPredicate(format: "identifier LIKE 'ChatChannelListCollectionViewCell'"))
    }

    static var list: XCUIElement {
        app.collectionViews["collectionView"]
    }

    /// The swipe action views are plain views, so only their buttons are in the tree; "more" is left of "delete".
    static var moreSwipeActionButton: XCUIElement {
        let buttons = app.buttons.matching(identifier: "actionButton")
        buttons.firstMatch.wait()
        return buttons.allElementsBoundByIndex.min { $0.frame.minX < $1.frame.minX } ?? buttons.firstMatch
    }

    enum ChannelActions {
        static var showChannelWithMessageId: XCUIElement { app.alerts.buttons["Show channel with message id"] }
        static var messageIdTextField: XCUIElement { app.alerts.textFields["debug_alert_textfield"] }
        static var okButton: XCUIElement { app.alerts.buttons["OK"] }
    }

    static func channel(withName: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(
            format: "identifier LIKE 'titleLabel' AND label LIKE '\(withName)'")).firstMatch
    }

    static func connectionLabel(withStatus: ChannelListPage.ConnectionStatus) -> XCUIElement {
        app.navigationBars.matching(NSPredicate(format: "identifier LIKE '\(withStatus.rawValue)'")).firstMatch
    }

    enum ConnectionStatus: String {
        case initialized
        case connecting
        case connected
        case disconnecting
        case disconnected
    }

    enum Attributes {
        static func name(in cell: XCUIElement) -> XCUIElement {
            cell.staticTexts["titleLabel"]
        }

        static func lastMessageTime(in cell: XCUIElement) -> XCUIElement {
            cell.staticTexts["timestampLabel"]
        }

        static func lastMessage(in cell: XCUIElement) -> XCUIElement {
            cell.staticTexts["subtitleLabel"]
        }

        static func avatar(in cell: XCUIElement) -> XCUIElement {
            cell.otherElements["ChatAvatarView"].images.firstMatch
        }

        static func readCount(in cell: XCUIElement) -> XCUIElement {
            cell.staticTexts["unreadCountLabel"]
        }

        static func statusCheckmark(
            for status: StreamChatTestMockServer.MessageDeliveryStatus?,
            in cell: XCUIElement
        ) -> XCUIElement {
            var identifier = "There is no status checkmark"
            if let status = status {
                identifier = "imageView_\(status.rawValue)"
            }
            return cell.images[identifier]
        }
    }
}
