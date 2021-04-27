//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageErrorIndicator: _Button, AppearanceProvider {
    override open func setUpAppearance() {
        super.setUpAppearance()
        setImage(appearance.images.messageListErrorIndicator, for: .normal)
        tintColor = appearance.colorPalette.alert
    }
}
