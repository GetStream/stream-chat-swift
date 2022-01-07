//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Button used to take an action on attachment being uploaded.
open class AttachmentActionButton: _Button, AppearanceProvider {
    /// The content saying which action the button represents
    public enum Content {
        case uploaded
        case restart
        case cancel
    }
    
    /// The content this button displays
    open var content: Content? {
        didSet { updateContentIfNeeded() }
    }
    
    /// The button size. It's 24x24 by default
    open var size: CGSize {
        .init(width: 24, height: 24)
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        contentEdgeInsets = .init(top: 6, left: 6, bottom: 6, right: 6)
        pin(anchors: [.width], to: size.width)
        pin(anchors: [.height], to: size.height)
    }
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        
        imageView?.contentMode = .scaleAspectFit
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }
    
    override open func updateContent() {
        super.updateContent()
        
        backgroundColor = content.map { _ in
            appearance.colorPalette.background4.withAlphaComponent(0.6)
        }
        
        let image: UIImage? = content.flatMap {
            switch $0 {
            case .uploaded:
                return appearance.images.whiteCheckmark.tinted(with: appearance.colorPalette.textInverted)
            case .restart:
                return appearance.images.restart.tinted(with: appearance.colorPalette.textInverted)
            case .cancel:
                return appearance.images.close.tinted(with: appearance.colorPalette.textInverted)
            }
        }
        setImage(image, for: .normal)
    }
}
