//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import SwiftUI
import XCTest

class ShrinkInputButton_Documentation_Tests: XCTestCase {
    func test_generateDocsSnapshot() {
        // Create a view to annotate and create documentation for.
        let view = ShrinkInputButton().withoutAutoresizingMaskConstraints

        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 50),
            view.heightAnchor.constraint(equalToConstant: 50)
        ])

        generateDocs(
            for: view,
            annotations: { _ in [] },
            name: "ShrinkInputButton_documentation",
            variants: .onlyUserInterfaceStyles
        )
    }
}
