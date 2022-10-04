//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class SlackReactionsMessageView: DemoChatMessageContentView {
    lazy var slackReactionsView: SlackReactionsListView = {
        let view = SlackReactionsListView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var isInPopupView = false

    override func layout(options: ChatMessageLayoutOptions) {
        super.layout(options: options)

        if options.contains(.customReactions) && !isInPopupView {
            addSubview(slackReactionsView)
            let bottomPadding: CGFloat = options.contains(.timestamp) ? 0 : 2
            NSLayoutConstraint.activate([
                slackReactionsView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
                slackReactionsView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
                slackReactionsView.topAnchor.constraint(equalTo: mainContainer.bottomAnchor, constant: bottomPadding),
                slackReactionsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
                slackReactionsView.widthAnchor.constraint(greaterThanOrEqualToConstant: 40)
            ])
        }
    }

    override func updateContent() {
        super.updateContent()

        slackReactionsView.content = content
    }
}
