//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIViewController {
    func addChildViewController(_ child: UIViewController, targetView superview: UIView) {
        child.willMove(toParent: self)
        addChild(child)
        superview.addSubview(child.view)
        child.didMove(toParent: self)
    }

    func removeFromParentViewController() {
        guard parent != nil else { return }

        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}
