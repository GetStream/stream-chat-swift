//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageFileAttachmentListView = _ChatMessageFileAttachmentListView<NoExtraData>

open class _ChatMessageFileAttachmentListView<ExtraData: ExtraDataTypes>: _View, ComponentsProvider {
    public var content: [ChatMessageFileAttachment] = [] {
        didSet { updateContentIfNeeded() }
    }

    public var didTapOnAttachment: ((ChatMessageFileAttachment) -> Void)?

    // MARK: - Subviews

    public private(set) lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        return stack.withoutAutoresizingMaskConstraints
    }()

    // MARK: - Overrides

    override open func setUpLayout() {
        embed(stackView, insets: .init(top: 4, leading: 4, bottom: 4, trailing: 4))
    }

    override open func updateContent() {
        stackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }

        content.forEach { attachment in
            let item = components.messageList.messageContentSubviews.attachmentSubviews.fileAttachmentItemView.init()
            item.didTapOnAttachment = { [weak self] in self?.didTapOnAttachment?($0) }
            item.content = attachment
            stackView.addArrangedSubview(item)
        }
    }
}
