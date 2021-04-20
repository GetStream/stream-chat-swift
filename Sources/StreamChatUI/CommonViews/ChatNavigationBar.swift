//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatNavigationBar<ExtraData: ExtraDataTypes>: _NavigationBar, UIConfigProvider {
    override open func setUpAppearance() {
        super.setUpAppearance()
        let backIcon = uiConfig.images.back
        backIndicatorTransitionMaskImage = backIcon
        backIndicatorImage = backIcon
    }
}
