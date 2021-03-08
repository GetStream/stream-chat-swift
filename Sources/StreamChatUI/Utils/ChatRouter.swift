//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

open class ChatRouter<Controller: UIViewController> {
    public unowned var rootViewController: Controller
    
    public var navigationController: UINavigationController? {
        rootViewController.navigationController
    }
    
    public required init(rootViewController: Controller) {
        self.rootViewController = rootViewController
    }
}
