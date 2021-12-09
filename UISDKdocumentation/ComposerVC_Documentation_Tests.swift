//
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import SwiftUI
import XCTest

class ComposerVC_Documentation_Tests: XCTestCase {

    func test_generateDocsSnapshot() {
        
        class TestComposerVC: ComposerVC {
            override func updateContent() {
                super.updateContent()

                composerView.attachmentButton.isHidden = false
                composerView.commandsButton.isHidden = false
                composerView.shrinkInputButton.isHidden = true
            }
        }

        // Create a view to annotate and create documentation for.
        let composerVC = TestComposerVC()
        composerVC.content = .init(
            text: "Hello World!",
            state: .edit,
            editingMessage: .mock(id: .unique, cid: .unique, text: "Hi World!", author: .mock(id: .unique)),
            quotingMessage: nil,
            threadMessage: .mock(id: .unique, cid: .unique, text: "", author: .mock(id: .unique)),
            attachments: [],
            mentionedUsers: .init(),
            command: nil
        )

        NSLayoutConstraint.activate([
            composerVC.view.widthAnchor.constraint(equalToConstant: 360)
        ])

        let composerView = composerVC.composerView

        generateDocs(
            for: composerVC.view,
            parentView: composerView,
            annotations: { _ in
                [ // Annotation types for the given subviews of the view
                    .init(view: composerView.headerView, descriptionLabelPosition: .top),
                    .init(view: composerView.leadingContainer, descriptionLabelPosition: .left),
                    .init(view: composerView.trailingContainer, descriptionLabelPosition: .right),
                    .init(view: composerView.bottomContainer, descriptionLabelPosition: .bottom),
                    .init(view: composerView.inputMessageView, descriptionLabelPosition: .bottomRight)
                ]
            },
            name: "ComposerVC_documentation", // Name of the file, will be suffixed with dark/light trait...
            variants: .onlyUserInterfaceStyles
        )
    }
}
