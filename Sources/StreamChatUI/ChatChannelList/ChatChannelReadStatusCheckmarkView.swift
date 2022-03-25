//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that shows a read/unread status of the last message in channel.
open class ChatChannelReadStatusCheckmarkView: _View, AppearanceProvider, SwiftUIRepresentable {
    /// An underlying type for status in the view.
    /// Right now corresponding functionality in LLC is missing and it will likely be replaced with the type from LLC.
    public enum Status {
        case read, unread, empty
    }
        
    /// The data this view component shows.
    open var content: Status = .empty {
        didSet { updateContentIfNeeded() }
    }
        
    /// The `UIImageView` instance that shows the read/unread status image.
    open private(set) lazy var imageView = UIImageView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "imageView")
    
    override open func tintColorDidChange() {
        super.tintColorDidChange()
        updateContentIfNeeded()
    }
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        imageView.contentMode = .scaleAspectFit
    }
    
    override open func setUpLayout() {
        embed(imageView)
    }
    
    override open func updateContent() {
        switch content {
        case .empty:
            imageView.image = nil
        case .read:
            imageView.image = appearance.images.readByAll
            imageView.tintColor = tintColor
        case .unread:
            imageView.image = appearance.images.messageSent
            imageView.tintColor = appearance.colorPalette.inactiveTint
        }
    }
}
