//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A Button subclass used for the create new channel action.
open class CreateChatChannelButton: _Button, AppearanceProvider {
    override open func setUpAppearance() {
        super.setUpAppearance()
        setImage(appearance.images.newChannel, for: .normal)
    }
}
