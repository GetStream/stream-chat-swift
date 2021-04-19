// LINK: https://getstream.io/chat/docs/ios-swift/ios_styles/?preview=1&language=swift#injecting-custom-subclass

import StreamChatUI
import UIKit

func snippets_ux_customizing_views_injecting_custom_subclass_2() {
    // > import UIKit
    // > import StreamChatUI

    class DuckBubbleView: ChatMessageContentView {
        lazy var duckView: UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "🦆"
            label.font = .systemFont(ofSize: 60)
            return label
        }()

        var incomingMessageConstraint: NSLayoutConstraint?
        var outgoingMessageConstraint: NSLayoutConstraint?

        override func setUpLayout() {
            super.setUpLayout()
            addSubview(duckView)
            duckView.centerYAnchor.constraint(equalTo: messageBubbleView!.bottomAnchor).isActive = true

            incomingMessageConstraint = duckView.centerXAnchor.constraint(equalTo: trailingAnchor)
            outgoingMessageConstraint = duckView.centerXAnchor.constraint(equalTo: leadingAnchor)
        }

        override func updateContent() {
            super.updateContent()
            let isOutgoing = message?.isSentByCurrentUser ?? false
            incomingMessageConstraint?.isActive = !isOutgoing
            outgoingMessageConstraint?.isActive = isOutgoing

            let isDuckInIt = message?.text.contains("duck") ?? false
            duckView.isHidden = !isDuckInIt
        }
    }
}
