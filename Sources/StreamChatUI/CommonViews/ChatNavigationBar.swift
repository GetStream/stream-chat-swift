//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatNavigationBar: _NavigationBar, AppearanceProvider {
    override open func setUpAppearance() {
        super.setUpAppearance()
        let backIcon = appearance.images.back
        backIndicatorTransitionMaskImage = backIcon
        backIndicatorImage = backIcon
    }
}
