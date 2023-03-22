//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// View which holds one or more file attachment views in a message or composer attachment view
open class ChatMessageFileAttachmentListView: _View, ComponentsProvider {
    /// Content of the attachment list - Array of `ChatMessageFileAttachment`
    open var content: [ChatMessageFileAttachment] = [] {
        didSet { updateContentIfNeeded() }
    }

    /// Closure what should happen on tapping the given attachment.
    open var didTapOnAttachment: ((ChatMessageFileAttachment) -> Void)?

    /// Closure that provides the view for each item. Provides a default implementation that callers
    /// can override.
    open lazy var itemViewProvider: ((ChatMessageFileAttachment) -> UIView?) = { [components = self.components] attachment in
        let item = components.fileAttachmentView.init()
        item.didTapOnAttachment = { [weak self] in self?.didTapOnAttachment?($0) }
        item.content = attachment
        return item
    }

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

    override open func prepareForReuse() {
        super.prepareForReuse()

        /// We are asking all subview of the containerStackView to prepareForReuse. This is helpful
        /// for AudioViews to make sure that the playback of a cell that goes off screen will be stopped.
        containerStackView.subviews
            .map { $0 as? _View }
            .forEach {
                $0?.prepareForReuse()
            }
    }

    override open func updateContent() {
        containerStackView.subviews
            .forEach { $0.removeFromSuperview() }

        content
            .compactMap(itemViewProvider)
            .forEach { containerStackView.addArrangedSubview($0) }
    }
}
