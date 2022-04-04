//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import SwiftUI
import XCTest

class OnlineIndicatorView_Documentation_Tests: XCTestCase {
    func test_generateDocsSnapshot() {
        // Create a view to annotate and create documentation for.
        let view = OnlineIndicatorView().withoutAutoresizingMaskConstraints
        
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 20),
            view.heightAnchor.constraint(equalToConstant: 20),
        ])
        
        generateDocs(
            for: view,
            annotations: { _ in [] },
            name: "OnlineIndicatorView_documentation",
            variants: .onlyUserInterfaceStyles
        )
    }
}
