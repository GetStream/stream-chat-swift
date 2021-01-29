//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatNavigationBar<ExtraData: ExtraDataTypes>: NavigationBar, UIConfigProvider {
    override public func defaultAppearance() {
        let backIcon = uiConfig.images.back
        backIndicatorTransitionMaskImage = backIcon
        backIndicatorImage = backIcon
    }
}
