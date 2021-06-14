//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import SwiftUI
import XCTest

class CreateChatChannelButton_Documentation_Tests: XCTestCase {
    func test_generateDocsSnapshot() {
        // Create a view to annotate and create documentation for.
        let view = CreateChatChannelButton().withoutAutoresizingMaskConstraints
        
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 50),
            view.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        generateDocs(
            for: view,
            annotations: [],
            name: "CreateChatChannelButton_documentation",
            variants: .onlyUserInterfaceStyles
        )
    }
}
