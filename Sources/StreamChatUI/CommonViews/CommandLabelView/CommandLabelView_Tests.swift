//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import SwiftUI
import XCTest

class CommandLabelView_Tests: XCTestCase {
    func test_emptyAppearance() {
        let view = CommandLabelView().withoutAutoresizingMaskConstraints
        AssertSnapshot(view)
    }
    
    func test_defaultAppearance() {
        let view = CommandLabelView().withoutAutoresizingMaskConstraints
        view.content = Command(name: "Giphy", description: "Send animated gifs", set: "", args: "")
        AssertSnapshot(view)
    }
}

@available(iOS 13, *)
class CommandLabelView_SwiftUI_Tests: iOS13TestCase {
    func test_defaultAppearance_SwiftUI() {
        let view = CommandLabelView.asView(
            Command(name: "Giphy", description: "Send animated gifs", set: "", args: "")
        )
        AssertSnapshot(SnapshotContainer(content: view))
    }
}
