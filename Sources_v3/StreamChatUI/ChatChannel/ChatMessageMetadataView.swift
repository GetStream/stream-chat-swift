//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageMetadataView<ExtraData: UIExtraDataTypes>: View {
    struct Layout {
        let timestamp: CGRect?
    }

    var layout: Layout? {
        didSet { setNeedsLayout() }
    }

    public var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContent() }
    }
    
    // MARK: - Subviews
    
    public private(set) lazy var timestampLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    // MARK: - Overrides

    override open func layoutSubviews() {
        super.layoutSubviews()

        if let frame = layout?.timestamp {
            timestampLabel.frame = frame
            timestampLabel.isHidden = false
        } else {
            timestampLabel.isHidden = true
        }
    }

    override public func defaultAppearance() {
        timestampLabel.textColor = .messageTimestamp
    }

    override open func setUpLayout() {
        addSubview(timestampLabel)
    }

    override open func updateContent() {
        timestampLabel.text = message?.createdAt.getFormattedDate(format: "hh:mm a")
    }
}

extension ChatMessageMetadataView {
    class LayoutProvider: ConfiguredLayoutProvider<ExtraData> {
        let label: UILabel = ChatMessageMetadataView().timestampLabel

        func heightForView(with data: _ChatMessageGroupPart<ExtraData>, limitedBy width: CGFloat) -> CGFloat {
            sizeForView(with: data, limitedBy: width).height
        }

        func sizeForView(with data: _ChatMessageGroupPart<ExtraData>, limitedBy width: CGFloat) -> CGSize {
            label.text = data.message.createdAt.getFormattedDate(format: "hh:mm a")
            return label.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        }

        func layoutForView(
            with data: _ChatMessageGroupPart<ExtraData>,
            of size: CGSize
        ) -> Layout {
            Layout(timestamp: CGRect(origin: .zero, size: size))
        }
    }
}
