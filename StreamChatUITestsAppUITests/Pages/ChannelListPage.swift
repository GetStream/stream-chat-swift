//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

class ChannelListPage {
    
    static var userAvatar: XCUIElement { app.otherElements["CurrentChatUserAvatarView"] }
    
    static var cells: XCUIElementQuery {
        app.cells.matching(NSPredicate(format: "identifier LIKE 'ChatChannelListCollectionViewCell'"))
    }
    
    struct Attributes {
        static func name(channelCell: XCUIElement) -> XCUIElement {
            channelCell.staticTexts["titleLabel"]
        }
        
        static func lastMessageTime(channelCell: XCUIElement) -> XCUIElement {
            channelCell.staticTexts["timestampLabel"]
        }
        
        static func lastMessage(channelCell: XCUIElement) -> XCUIElement {
            channelCell.staticTexts["subtitleLabel"]
        }
        
        static func avatar(channelCell: XCUIElement) -> XCUIElement {
            channelCell.otherElements["ChatAvatarView"].images.firstMatch
        }
    }

}
