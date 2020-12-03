//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

class СhatMessageCollectionViewCell<ExtraData: UIExtraDataTypes>: UICollectionViewCell, UIConfigProvider {
    static var reuseId: String { String(describing: self) }

    struct Layout {
        let messageView: CGRect?
        let messageViewLayout: ChatMessageContentView<ExtraData>.Layout?
    }

    var layout: Layout? {
        didSet { setNeedsLayout() }
    }

    var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContent() }
    }
    
    // MARK: - Subviews

    public private(set) lazy var messageView = uiConfig.messageList.messageContentView.init()
    
    // MARK: - Lifecycle

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        guard superview != nil else { return }

        setUpLayout()
        updateContent()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        messageView.isHidden = layout?.messageView == nil
        if let messageFrame = layout?.messageView {
            messageView.frame = messageFrame
        }
        messageView.layout = layout?.messageViewLayout
    }

    func setUpLayout() {
        contentView.addSubview(messageView)
    }

    func updateContent() {
        messageView.message = message
    }

    // MARK: - Overrides

    override func prepareForReuse() {
        super.prepareForReuse()

        message = nil
    }
}

extension СhatMessageCollectionViewCell {
    class LayoutProvider: ConfiguredLayoutProvider<ExtraData> {
        lazy var contentSizer = ChatMessageContentView<ExtraData>.LayoutProvider(parent: self)

        func heightForCell(with data: _ChatMessageGroupPart<ExtraData>, limitedBy width: CGFloat) -> CGFloat {
            sizeForCell(with: data, limitedBy: width).height
        }

        func sizeForCell(with data: _ChatMessageGroupPart<ExtraData>, limitedBy width: CGFloat) -> CGSize {
            let workWidth = width * uiConfig.messageList.maxMessageWidth
            let height = contentSizer.heightForView(with: data, limitedBy: workWidth)
            return CGSize(width: width, height: height)
        }

        func layoutForCell(
            with data: _ChatMessageGroupPart<ExtraData>,
            limitedBy width: CGFloat
        ) -> Layout {
            let workWidth = width * uiConfig.messageList.maxMessageWidth
            let margin: CGFloat = uiConfig.messageList.defaultMargins
            let size = contentSizer.sizeForView(with: data, limitedBy: workWidth)
            let layout = contentSizer.layoutForView(with: data, of: size)
            let originX = data.isSentByCurrentUser
                ? width - size.width - margin
                : margin
            return Layout(
                messageView: CGRect(origin: CGPoint(x: originX, y: 0), size: size),
                messageViewLayout: layout
            )
        }
    }
}
