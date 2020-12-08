//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageMetadataView<ExtraData: UIExtraDataTypes>: View, UIConfigProvider {
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

    override public func defaultAppearance() {
        timestampLabel.textColor = uiConfig.colorPalette.messageTimestampText
    }

    override open func setUpLayout() {
        embed(timestampLabel)
    }

    override open func updateContent() {
        timestampLabel.text = message?.createdAt.getFormattedDate(format: "hh:mm a")
    }
}
