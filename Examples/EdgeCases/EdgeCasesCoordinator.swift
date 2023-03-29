//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Atlantis
import StreamChat
import UIKit

class EdgeCasesCoordinator {
    let chatClient: ChatClient

    init() {
        let config = ChatClientConfig(apiKeyString: "")
        chatClient = ChatClient(config: config)
    }

    func start(with window: UIWindow) {
        Atlantis.start()
        configureStream()

        let viewController = UIViewController()
        viewController.view.backgroundColor = .red
        window.rootViewController = viewController
        window.makeKeyAndVisible()
    }

    private func configureStream() {
        StreamRuntimeCheck.assertionsEnabled = true
    }
}
