//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI
import UIKit

final class DemoChatChannelVC: ChatChannelVC {
    override func setUp() {
        let asyncQuery = AsyncQuery<ChannelQuery> { [weak self] completion in
            self?.messageComposerVC.composerView.inputMessageView.textView.isUserInteractionEnabled = false
            self?.getChannelId { channelId in
                self?.messageComposerVC.composerView.inputMessageView.textView.isUserInteractionEnabled = true
                self?.messageComposerVC.channelController = self?.client.channelController(for: channelId)
                completion(.success(ChannelQuery(cid: channelId)))
            }
        }
        channelController = client.channelController(asyncQuery: asyncQuery)
        super.setUp()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let debugButton = UIBarButtonItem(
            image: UIImage(systemName: "ladybug.fill")!,
            style: .plain,
            target: self,
            action: #selector(debugTap)
        )
        navigationItem.rightBarButtonItems?.append(debugButton)
    }

    @objc private func debugTap() {
        guard let cid = channelController.cid else { return }

        let channelListVC: DemoChatChannelListVC
        if let mainVC = splitViewController?.viewControllers.first as? UINavigationController,
           let _channelListVC = mainVC.viewControllers.first as? DemoChatChannelListVC {
            channelListVC = _channelListVC
        } else if let _channelListVC = navigationController?.viewControllers.first as? DemoChatChannelListVC {
            channelListVC = _channelListVC
        } else {
            return
        }

        channelListVC.demoRouter?.didTapMoreButton(for: cid)
    }

    func getChannelId(completion: @escaping (ChannelId) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            completion(try! ChannelId(cid: "messaging:!members-gZvIpUUNpv-adclg-zxhJjCb7a3KvwYBBQHvCqynCeQ"))
        }
    }
}
