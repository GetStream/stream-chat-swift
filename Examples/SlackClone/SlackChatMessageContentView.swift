//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class SlackChatMessageContentView: ChatMessageContentView {
    override var maxContentWidthMultiplier: CGFloat { 1 }

    lazy var slackReactionsView: SlackReactionsView = {
        let view = SlackReactionsView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var isInPopupView = false

    override func layout(options: ChatMessageLayoutOptions) {
        super.layout(options: options)

        mainContainer.alignment = .leading
        bubbleThreadFootnoteContainer.changeOrdering()
        bubbleContentContainer.directionalLayoutMargins = .zero

        if options.contains(.slackReactions) && !isInPopupView {
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

    override func createTextView() -> UITextView {
        let textView = super.createTextView()
        textView.textContainerInset = .zero
        return textView
    }
}

extension ContainerStackView {
    func changeOrdering() {
        let subviews = self.subviews
        removeAllArrangedSubviews()
        addArrangedSubviews(subviews.reversed())
    }
}
