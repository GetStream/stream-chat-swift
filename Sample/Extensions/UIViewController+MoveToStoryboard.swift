//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIViewController {
    func moveToStoryboard(_ storyboard: UIStoryboard, options: UIView.AnimationOptions = []) {
        let initial = storyboard.instantiateInitialViewController()
        UIView.transition(with: view.window!, duration: 0.5, options: options, animations: {
            self.view.window?.rootViewController = initial
        })
    }
}
