//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import SwiftUI
import XCTest

final class CommandLabelView_Tests: XCTestCase {
    func test_emptyAppearance() {
        let view = CommandLabelView().withoutAutoresizingMaskConstraints
        AssertSnapshot(view)
    }

    func test_defaultAppearance() {
        let view = CommandLabelView().withoutAutoresizingMaskConstraints
        view.content = Command(args: "", description: "Send animated gifs", name: "Giphy", set: "")
        AssertSnapshot(view)
    }
}

@available(iOS 13, *)
final class CommandLabelView_SwiftUI_Tests: iOS13TestCase {
    func test_defaultAppearance_SwiftUI() {
        let view = CommandLabelView.asView(
            Command(args: "", description: "Send animated gifs", name: "Giphy", set: "")
        )
        AssertSnapshot(SnapshotContainer(content: view))
    }
}
