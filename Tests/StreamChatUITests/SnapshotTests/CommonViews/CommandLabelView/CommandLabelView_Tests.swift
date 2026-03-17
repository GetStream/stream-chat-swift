//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import SwiftUI
import XCTest

@MainActor final class CommandLabelView_Tests: XCTestCase {
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
