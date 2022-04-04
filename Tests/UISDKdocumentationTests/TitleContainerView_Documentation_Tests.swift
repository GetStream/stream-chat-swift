//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import SwiftUI
import XCTest

class TitleContainerView_Documentation_Tests: XCTestCase {
    // Example of usage for generating UISDK documentation:
    
    func test_generateDocsSnapshot() {
        // Create a view to annotate and create documentation for.
        let view = TitleContainerView().withoutAutoresizingMaskConstraints
        view.content = (title: "Luke Skywalker", subtitle: "Last seen a long time ago...")
        
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 320),
            view.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        generateDocs(
            for: view,
            annotations: { view in
                [ // Annotation types for the given subviews of the view
                    .init(view: view.titleLabel, descriptionLabelPosition: .topLeft),
                    .init(view: view.subtitleLabel, descriptionLabelPosition: .topRight)
                ]
            },
            name: "TitleContainerView_documentation", // Name of the file, will be suffixed with dark/light trait...
            variants: .onlyUserInterfaceStyles
        )
    }
}
