//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that wraps attachment preview and provides default controls (ie: remove button) for it.
open class AttachmentPreviewContainer: _View, AppearanceProvider {
    /// A closure handler that is called when the discard button of the attachment is clicked
    public var discardButtonHandler: (() -> Void)?
    
    /// A button to remove the attachment from the collection of attachments.
    open private(set) lazy var discardButton: UIButton = UIButton()
        .withoutAutoresizingMaskConstraints

    override open func setUp() {
        super.setUp()
        
        discardButton.addTarget(self, action: #selector(discard), for: .touchUpInside)
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        addSubview(discardButton)
        
        discardButton.topAnchor.pin(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        discardButton.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        discardButton.setContentHuggingPriority(.required, for: .horizontal)
    }
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        
        discardButton.setImage(appearance.images.discardAttachment, for: .normal)
    }
    
    open func embed(attachmentView view: UIView) {
        embed(view)
        sendSubviewToBack(view)
    }
    
    @objc open func discard() {
        discardButtonHandler?()
    }
}
