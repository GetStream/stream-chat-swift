//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that shows a read/unread status of the last message in channel.
internal typealias ChatChannelReadStatusCheckmarkView = _ChatChannelReadStatusCheckmarkView<NoExtraData>

/// A view that shows a read/unread status of the last message in channel.
internal class _ChatChannelReadStatusCheckmarkView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider, SwiftUIRepresentable {
    /// An underlying type for status in the view.
    /// Right now corresponding functionality in LLC is missing and it will likely be replaced with the type from LLC.
    internal enum Status {
        case read, unread, empty
    }
        
    /// The data this view component shows.
    internal var content: Status = .empty {
        didSet { updateContentIfNeeded() }
    }
        
    /// The `UIImageView` instance that shows the read/unread status image.
    internal private(set) lazy var imageView = UIImageView().withoutAutoresizingMaskConstraints
    
    override internal func tintColorDidChange() {
        super.tintColorDidChange()
        updateContentIfNeeded()
    }
    
    override public func defaultAppearance() {
        super.defaultAppearance()
        
        imageView.contentMode = .scaleAspectFit
    }
    
    override internal func setUpLayout() {
        embed(imageView)
    }
    
    override open func updateContent() {
        switch content {
        case .empty:
            imageView.image = nil
        case .read:
            imageView.image = uiConfig.images.channelListReadByAll
            imageView.tintColor = tintColor
        case .unread:
            imageView.image = uiConfig.images.channelListSent
            imageView.tintColor = uiConfig.colorPalette.inactiveTint
        }
    }
}
