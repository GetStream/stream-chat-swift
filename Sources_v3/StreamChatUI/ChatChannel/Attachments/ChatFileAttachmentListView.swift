//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatFileAttachmentListView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    public var content: AttachmentListViewData<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    public private(set) lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.isLayoutMarginsRelativeArrangement = true
        stack.preservesSuperviewLayoutMargins = true
        stack.axis = .vertical
        return stack.withoutAutoresizingMaskConstraints
    }()

    // MARK: - Overrides

    override public func defaultAppearance() {
        stackView.spacing = 4
        directionalLayoutMargins = .init(top: 4, leading: 4, bottom: 4, trailing: 4)
    }

    override open func setUpLayout() {
        embed(stackView)
    }

    override open func updateContent() {
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
