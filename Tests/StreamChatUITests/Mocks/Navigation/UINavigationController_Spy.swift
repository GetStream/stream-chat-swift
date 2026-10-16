//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

/// Records pops instead of performing them, so tests don't depend on a window or transition animations.
final class UINavigationController_Spy: UINavigationController {
    var popToViewControllerCalledWith: UIViewController?

    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        popToViewControllerCalledWith = viewController
        return nil
    }
}
