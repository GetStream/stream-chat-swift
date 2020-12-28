//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The type describing message reaction appearance.
public protocol ReactionAppearanceType {
    var smallIcon: UIImage { get }
    var largeIcon: UIImage { get }
}

/// The default `ReactionAppearanceType` implementation without any additional data
/// which can be used to provide custom icons for message reaction.
public struct ReactionAppearance: ReactionAppearanceType {
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
