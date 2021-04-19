//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageFileAttachmentListView = _ChatMessageFileAttachmentListView<NoExtraData>

open class _ChatMessageFileAttachmentListView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    public var content: [ChatMessageFileAttachment] = [] {
        didSet { updateContentIfNeeded() }
    }

    public var didTapOnAttachment: ((ChatMessageFileAttachment) -> Void)? {
        didSet { updateActionHandlers() }
    }

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

        content.forEach {
            let item = uiConfig.messageList.messageContentSubviews.attachmentSubviews.fileAttachmentItemView.init()
            item.content = $0
            stackView.addArrangedSubview(item)
        }

        updateActionHandlers()
    }

    private func updateActionHandlers() {
        let itemViews = stackView.arrangedSubviews.compactMap { $0 as? ItemView }
        zip(itemViews, content).forEach { (item, attachment) in
            item.didTapOnAttachment = { [weak self] in
                self?.didTapOnAttachment?(attachment)
            }
        }
    }
}
