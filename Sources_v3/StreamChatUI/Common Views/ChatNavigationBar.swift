//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatNavigationBar: NavigationBar {
    override public func defaultAppearance() {
        let backIcon = UIImage(named: "icn_back", in: Bundle(for: Self.self), compatibleWith: nil)
        backIndicatorTransitionMaskImage = backIcon
        backIndicatorImage = backIcon
    }
}
