//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class SlackChatMessageContentView: ChatMessageContentView {
    override var maxContentWidthMultiplier: CGFloat { 1 }

    override func layout(options: ChatMessageLayoutOptions) {
        super.layout(options: options)

        mainContainer.alignment = .leading
        bubbleThreadFootnoteContainer.changeOrdering()
        bubbleContentContainer.directionalLayoutMargins = .zero
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
