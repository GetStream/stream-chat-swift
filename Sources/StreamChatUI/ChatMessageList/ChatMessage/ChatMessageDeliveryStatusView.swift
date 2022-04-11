//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that displays message delivery receipts.
open class ChatMessageDeliveryStatusView: _Control, ThemeProvider {
    public struct Content {
        public var message: ChatMessage
        public var channel: ChatChannel
        
        public init(message: ChatMessage, channel: ChatChannel) {
            self.message = message
            self.channel = channel
        }
    }
    
    /// The content the view displays.
    open var content: Content? {
        didSet { updateContentIfNeeded() }
    }
    
    override open var isHighlighted: Bool {
        didSet { alpha = state == .normal ? 1 : 0.5 }
    }
    
    /// The label showing number of message reads.
    open private(set) lazy var messageReadСountsLabel = UILabel()
        .withAccessibilityIdentifier(identifier: "messageReadСountsLabel")
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints
    
    /// The image view showing read state of the message.
    open private(set) lazy var messageDeliveryReceiptImageView = UIImageView()
        .withAccessibilityIdentifier(identifier: "messageDeliveryReceiptImageView")
        .withoutAutoresizingMaskConstraints
    
    /// The container embedding `messageReadСountsLabel` and `messageDeliveryReceiptImageView`.
    open private(set) lazy var stackView = UIStackView()
        .withAccessibilityIdentifier(identifier: "stackView")
        .withoutAutoresizingMaskConstraints
    
    override open func setUp() {
        super.setUp()
        
        stackView.isUserInteractionEnabled = false
        isUserInteractionEnabled = false
    }
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        
        messageDeliveryReceiptImageView.contentMode = .center
        messageReadСountsLabel.textColor = appearance.colorPalette.accentPrimary
        messageReadСountsLabel.font = appearance.fonts.footnoteBold
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
                
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.addArrangedSubview(messageReadСountsLabel)
        stackView.addArrangedSubview(messageDeliveryReceiptImageView)
        embed(stackView)
    }
    
    override open func updateContent() {
        super.updateContent()
        
        messageDeliveryReceiptImageView.image = content.flatMap {
            switch $0.message.localState {
            case .pendingSend, .sending, .pendingSync, .syncing, .deleting:
                return appearance.images.messageDeliveryStatusSending
            case .sendingFailed, .syncingFailed, .deletingFailed:
                return nil
            case nil:
                return $0.message.readByCount > 0
                    ? appearance.images.messageDeliveryStatusRead
                    : appearance.images.messageDeliveryStatusSent
            }
        }
        messageDeliveryReceiptImageView.tintColor = (content?.message.readByCount ?? 0) > 0
            ? appearance.colorPalette.accentPrimary
            : appearance.colorPalette.textLowEmphasis
        
        messageReadСountsLabel.text = content.flatMap {
            guard
                // Read counts only make sense for sent messages.
                $0.message.localState == nil,
                // Read counts should not be shown in direct messaging channels.
                $0.channel.memberCount > 2,
                // Show read count if there's at least one member who viewed the message.
                $0.message.readByCount > 0
            else { return nil }
            
            return "\($0.message.readByCount)"
        }
        messageReadСountsLabel.isVisible = messageReadСountsLabel.text != nil
    }
}
