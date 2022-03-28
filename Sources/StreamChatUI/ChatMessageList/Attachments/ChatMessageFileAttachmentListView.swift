//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// View which holds one or more file attachment views in a message or composer attachment view
open class ChatMessageFileAttachmentListView: _View, ComponentsProvider {
    /// Content of the attachment llist - Array of `ChatMessageFileAttachment`
    open var content: [ChatMessageFileAttachment] = [] {
        didSet { updateContentIfNeeded() }
    }
    
    /// Closure what should happen on tapping the given attachment.
    open var didTapOnAttachment: ((ChatMessageFileAttachment) -> Void)?
    
    /// Container which holds one or multiple attachment views in self.
    open private(set) lazy var containerStackView: ContainerStackView = ContainerStackView().withoutAutoresizingMaskConstraints

    override open func setUpLayout() {
        directionalLayoutMargins = .init(top: 4, leading: 4, bottom: 4, trailing: 4)
        addSubview(containerStackView)
        containerStackView.pin(to: layoutMarginsGuide)
        
        containerStackView.axis = .vertical
        containerStackView.distribution = .equal
        containerStackView.spacing = 4
    }

    override open func updateContent() {
        containerStackView.subviews.forEach { $0.removeFromSuperview() }

        content.forEach { attachment in
            let item = components.fileAttachmentView.init()
            item.didTapOnAttachment = { [weak self] in self?.didTapOnAttachment?($0) }
            item.content = attachment
            containerStackView.addArrangedSubview(item)
        }
    }
}
