//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageFileAttachmentListView = _ChatMessageFileAttachmentListView<NoExtraData>

internal class _ChatMessageFileAttachmentListView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    public var content: _ChatMessageAttachmentListViewData<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    internal private(set) lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        return stack.withoutAutoresizingMaskConstraints
    }()

    // MARK: - Overrides

    override internal func setUpLayout() {
        embed(stackView, insets: .init(top: 4, leading: 4, bottom: 4, trailing: 4))
    }

    override internal func updateContent() {
        stackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }

        content?.items.forEach {
            let item = uiConfig.messageList.messageContentSubviews.attachmentSubviews.fileAttachmentItemView.init()
            item.content = $0
            stackView.addArrangedSubview(item)
        }
    }
}
