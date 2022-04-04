//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import SwiftUI
import XCTest

class SendButton_Documentation_Tests: XCTestCase {
    func test_generateDocsSnapshot() {
        // Create a view to annotate and create documentation for.
        let view = SendButton().withoutAutoresizingMaskConstraints
            
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 50),
            view.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        view.isEnabled = true
        generateDocs(
            for: view,
            annotations: { _ in [] },
            name: "SendButton_documentation_enabled",
            variants: .onlyUserInterfaceStyles
        )
        
        view.isEnabled = false
        generateDocs(
            for: view,
            annotations: { _ in [] },
            name: "SendButton_documentation_disabled",
            variants: .onlyUserInterfaceStyles
        )
    }
}
