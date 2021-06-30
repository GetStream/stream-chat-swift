//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class iMessageComposerView: ComposerView {
    override func setUpLayout() {
        super.setUpLayout()

        // Remove the commands button, iMessage doesn't have it
        leadingContainer.removeArrangedSubview(commandsButton)

        // Move the send button from the trailing container to input container
        trailingContainer.removeArrangedSubview(sendButton)
        inputMessageView.inputTextContainer.addArrangedSubview(sendButton)

        // Remove spacing in leading container for bigger attachment button
        leadingContainer.spacing = 0

        // Make send button inside input container aligned to bottom
        inputMessageView.inputTextContainer.alignment = .bottom
    }
    
    override func setUpAppearance() {
        super.setUpAppearance()

        // Adjust the input corner radius since width is now bigger
        inputMessageView.container.layer.cornerRadius = 18
    }
}
