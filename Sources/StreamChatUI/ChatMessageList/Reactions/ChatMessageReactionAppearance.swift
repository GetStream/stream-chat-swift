//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The type describing message reaction appearance.
public protocol ChatMessageReactionAppearanceType {
    var smallIcon: UIImage { get }
    var largeIcon: UIImage { get }
}

/// The default `ReactionAppearanceType` implementation without any additional data
/// which can be used to provide custom icons for message reaction.
public struct ChatMessageReactionAppearance: ChatMessageReactionAppearanceType {
    public let smallIcon: UIImage
    public let largeIcon: UIImage
    
    public init(
        smallIcon: UIImage,
        largeIcon: UIImage
    ) {
        self.smallIcon = smallIcon
        self.largeIcon = largeIcon
    }
}
