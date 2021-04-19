// LINK: https://getstream.io/chat/docs/ios-swift/ios_styles/?preview=1&language=swift#changing-component-subviews-relative-arrangement,-or-removing-subview

import StreamChatUI
import UIKit

func snippets_ux_customizing_views_changing_component_arrangement() {
    // > import UIKit
    // > import StreamChatUI

    // 1. Create custom UI component subclass.
    class InteractiveAttachmentView: ChatMessageInteractiveAttachmentView {
        // 2. Override `setUpLayout` and provide custom subviews arrangement.
        override open func setUpLayout() {
            // 3. Add only `preview` and `actionsStackView`.
            addSubview(preview)
            addSubview(actionsStackView)

            // 4. Make the action buttons stack vertical.
            actionsStackView.axis = .vertical

            // 5. Set up the necessary constraints.
            NSLayoutConstraint.activate([
                preview.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                preview.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                preview.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                preview.heightAnchor.constraint(equalTo: preview.widthAnchor),
                
                actionsStackView.topAnchor.constraint(equalTo: preview.bottomAnchor),
                actionsStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                actionsStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                actionsStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
    }
}
