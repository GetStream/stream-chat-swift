//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A Button subclass that should be used for creating new channels.
open class ChatChannelCreateNewButton: _Button, AppearanceProvider {
    override open func setUpAppearance() {
        super.setUpAppearance()
        setImage(appearance.images.newChat, for: .normal)
    }
}
