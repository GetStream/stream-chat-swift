//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import SwiftUI
import XCTest

class ChatAvatarView_Documentation_Tests: XCTestCase {
    func test_generateDocsSnapshot() {
        // Create a view to annotate and create documentation for.
        let view = ChatAvatarView().withoutAutoresizingMaskConstraints
        view.imageView.image = TestImages.yoda.image
            
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 100),
            view.heightAnchor.constraint(equalToConstant: 100),
        ])
        
        generateDocs(
            for: view,
            annotations: { _ in [] },
            name: "ChatAvatarView_documentation",
            variants: .onlyUserInterfaceStyles
        )
    }
}

