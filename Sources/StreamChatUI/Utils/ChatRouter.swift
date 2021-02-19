//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

internal class ChatRouter<Controller: UIViewController> {
    internal weak var rootViewController: Controller?
    
    internal var navigationController: UINavigationController? {
        rootViewController?.navigationController
    }
    
    internal required init(rootViewController: Controller) {
        self.rootViewController = rootViewController
    }
}
