//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import SwiftUI
import XCTest

class CommandLabelView_Documentation_Tests: XCTestCase {
    func test_generateDocsSnapshot() {
        // Create a view to annotate and create documentation for.
        let view = CommandLabelView().withoutAutoresizingMaskConstraints
        view.content = Command(name: "Giphy", description: "", set: "", args: "")
            
        generateDocs(
            for: view,
            annotations: { view in
                [
                    .init(view: view.iconView, descriptionLabelPosition: .topLeft),
                    .init(view: view.nameLabel, descriptionLabelPosition: .topRight)
                ]
            },
            name: "CommandLabelView_documentation",
            variants: .onlyUserInterfaceStyles
        )
    }
}

