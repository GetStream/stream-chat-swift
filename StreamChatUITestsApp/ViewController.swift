//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {

    var startButton: UIButton!
    var streamChat = StreamChatWrapper()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        startButton = UIButton(type: .system)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.setTitle("Start Chat", for: .normal)
        startButton.accessibilityIdentifier = "TestApp.Start"
        startButton.addTarget(self, action: #selector(didTap), for: .touchUpInside)

        view.addSubview(startButton)
        NSLayoutConstraint.activate([
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc func didTap() {

        // Setup chat client
        streamChat.setupChatClient(with: .default)

        // create UI
        let channelList = streamChat.makeChannelListViewController()

        // push to detail presentation
        self.navigationController?.pushViewController(channelList, animated: false)
    }


}

