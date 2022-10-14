//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The navigation controller with navigation bar of `ChatNavigationBar` type.
open class NavigationVC: UINavigationController {
    public required init(
        rootViewController: UIViewController,
        navigationBarClass: ChatNavigationBar.Type = ChatNavigationBar.self,
        toolbarClass: AnyClass? = nil
    ) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
        viewControllers = [rootViewController]
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
