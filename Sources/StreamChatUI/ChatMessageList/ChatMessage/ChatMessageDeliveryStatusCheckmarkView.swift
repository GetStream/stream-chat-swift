//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that displays message delivery receipts.
open class ChatMessageDeliveryStatusCheckmarkView: _View, ThemeProvider {
    /// The content shown by the view.
    public struct Content {
        public var deliveryStatus: MessageDeliveryStatus
    }
    
    /// The data this view component shows.
    open var content: Content? {
        didSet { updateContentIfNeeded() }
    }
    
    /// The image view showing read state of the message.
    open private(set) lazy var imageView = UIImageView()
        .withoutAutoresizingMaskConstraints
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        
        imageView.contentMode = .scaleAspectFit
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        let size: CGFloat = 14
        widthAnchor.pin(equalToConstant: size).isActive = true
        heightAnchor.pin(equalToConstant: size).isActive = true
        
        embed(imageView)
    }
    
    override open func updateContent() {
        super.updateContent()
        
        imageView.image = content.flatMap {
            switch $0.deliveryStatus {
            case .pending:
                return appearance.images.messageDeliveryStatusSending
            case .sent:
                return appearance.images.messageDeliveryStatusSent
            case .read:
                return appearance.images.messageDeliveryStatusRead
            case .failed:
                return appearance.images.messageDeliveryStatusFailed
            default:
                return nil
            }
        }
                
        imageView.tintColor = content.map {
            switch $0.deliveryStatus {
            case .read:
                return appearance.colorPalette.accentPrimary
            case .failed:
                return appearance.colorPalette.alert
            default:
                return appearance.colorPalette.textLowEmphasis
            }
        }
        
        imageView.accessibilityIdentifier = imageViewAccessibilityIdentifier
    }
    
    // MARK: - Private
    
    private var imageViewAccessibilityIdentifier: String {
        let prefix = "imageView"
        
        guard let status = content?.deliveryStatus else {
            return prefix
        }
        
        return "\(prefix)_\(status.rawValue)"
    }
}
