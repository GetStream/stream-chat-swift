//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatChannelListCollectionViewCell_Tests: XCTestCase {
    // defaultAppearance() is called multiple times so backgroundColor is changed by
    // ChatChannelListItemView and snapshot test is not possible.
    func test_isHighlighted() {
        let view = ChatChannelListCollectionViewCell().withoutAutoresizingMaskConstraints
        view.executeLifecycleMethods()
        
        XCTAssertEqual(view.appearance.colorPalette.background, view.itemView.backgroundColor)
        
        view.isHighlighted = true
        
        XCTAssertEqual(view.appearance.colorPalette.highlightedBackground, view.itemView.backgroundColor)
    }
}
