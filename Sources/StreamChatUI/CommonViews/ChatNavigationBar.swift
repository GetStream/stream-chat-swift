//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal class ChatNavigationBar<ExtraData: ExtraDataTypes>: _NavigationBar, UIConfigProvider {
    override internal func defaultAppearance() {
        let backIcon = uiConfig.images.back
        backIndicatorTransitionMaskImage = backIcon
        backIndicatorImage = backIcon
    }
}
