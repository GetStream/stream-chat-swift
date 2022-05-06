//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest
import StreamChat

enum ChannelListPage {
    
    static var userAvatar: XCUIElement { app.otherElements["CurrentChatUserAvatarView"] }
    
    static var cells: XCUIElementQuery {
        app.cells.matching(NSPredicate(format: "identifier LIKE 'ChatChannelListCollectionViewCell'"))
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

        static func readCount(messageCell: XCUIElement) -> XCUIElement {
            messageCell.staticTexts["unreadCountLabel"]
        }

        static func statusCheckmark(for status: MessageDeliveryStatus, with messageCell: XCUIElement) -> XCUIElement {
            messageCell.images["imageView_\(status.rawValue)"]
        }
    }

}
