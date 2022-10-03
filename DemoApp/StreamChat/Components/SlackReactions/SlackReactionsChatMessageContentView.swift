//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class SlackReactionsChatMessageContentView: DemoChatMessageContentView {
    lazy var slackReactionsView: SlackReactionsView = {
        let view = SlackReactionsView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func layout(options: ChatMessageLayoutOptions) {
        super.layout(options: options)

        if options.contains(.customReactions) {
            addSubview(slackReactionsView)
            let bottomPadding: CGFloat = options.contains(.timestamp) ? 0 : 2
            NSLayoutConstraint.activate([
                slackReactionsView.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor, constant: 8),
                slackReactionsView.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor, constant: -8),
                slackReactionsView.topAnchor.constraint(equalTo: mainContainer.bottomAnchor, constant: bottomPadding),
                slackReactionsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
            ])
        }
    }

    override func updateContent() {
        super.updateContent()

        slackReactionsView.content = content
    }
}
