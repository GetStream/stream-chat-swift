//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatCommonUI
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

@MainActor final class ChatChannelListCollectionViewCell_Tests: XCTestCase {
    // defaultAppearance() is called multiple times so backgroundColor is changed by
    // ChatChannelListItemView and snapshot test is not possible.
    func test_isHighlighted() {
        let view = ChatChannelListCollectionViewCell().withoutAutoresizingMaskConstraints
        view.executeLifecycleMethods()

        XCTAssertEqual(view.appearance.colorPalette.backgroundCoreApp, view.itemView.backgroundColor)

        view.isHighlighted = true

        XCTAssertEqual(view.appearance.colorPalette.backgroundCoreSurfaceStrong, view.itemView.backgroundColor)
    }
}
