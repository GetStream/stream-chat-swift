//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// View which holds one or more file attachment views in a message or composer attachment view
open class ChatMessageFileAttachmentListView: _View, ComponentsProvider {
    /// Content of the attachment list - Array of `ChatMessageFileAttachment`
    open var content: [ChatMessageFileAttachment] = [] {
        didSet { updateContentIfNeeded() }
    }

    /// Closure which notifies when the user tapped the attachment.
    open var didTapOnAttachment: ((ChatMessageFileAttachment) -> Void)?

    /// Closure which notifies when the user tapped an attachment action. (Ex: Retry)
    open var didTapActionOnAttachment: ((ChatMessageFileAttachment) -> Void)?

    /// Container which holds one or multiple attachment views in self.
    open private(set) lazy var containerStackView: ContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "containerStackView")

    override open func setUpLayout() {
        directionalLayoutMargins = .init(top: 4, leading: 4, bottom: 4, trailing: 4)
        addSubview(containerStackView)
        containerStackView.pin(to: layoutMarginsGuide)

        containerStackView.axis = .vertical
        containerStackView.spacing = 4
    }

    override open func updateContent() {
        containerStackView.subviews.forEach { $0.removeFromSuperview() }

        content.forEach { attachment in
            let item = components.fileAttachmentView.init()
            item.didTapOnAttachment = { [weak self] in self?.didTapOnAttachment?($0) }
            item.didTapActionOnAttachment = { [weak self] in self?.didTapActionOnAttachment?($0) }
            item.content = attachment
            containerStackView.addArrangedSubview(item)
        }
    }
}
