//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI
import UIKit

final class DemoChatChannelVC: ChatChannelVC, UIGestureRecognizerDelegate {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        hidesBottomBarWhenPushed = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Custom Header Views

    // Example of custom header views.
    // The same code should be provided to `ChatThreadVC` if you want the same behaviour in threads.

    lazy var messageListHeaderView: UIView? = {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 60))
        headerView.backgroundColor = appearance.colorPalette.background

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "All messages loaded"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemGray
        headerView.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            label.centerXAnchor.constraint(equalTo: headerView.centerXAnchor)
        ])

        return headerView
    }()

    lazy var loadingViewIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.startAnimating()
        return indicator
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let debugButton = UIBarButtonItem(
            image: UIImage(systemName: "ladybug.fill")!,
            style: .plain,
            target: self,
            action: #selector(debugTap)
        )
        navigationItem.rightBarButtonItems?.append(debugButton)

        // Custom back button to make sure swipe back gesture is not overridden.
        let customBackButton = UIBarButtonItem(
            title: "Back",
            style: .plain,
            target: self,
            action: #selector(goBack)
        )
        navigationItem.leftBarButtonItems = [customBackButton]
        navigationController?.interactivePopGestureRecognizer?.delegate = self
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

    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Loading previous and next messages state handling.

    override func loadPreviousMessages(completion: @escaping (Error?) -> Void) {
        messageListVC.headerView = loadingViewIndicator
        super.loadPreviousMessages(completion: completion)
    }

    override func didFinishLoadingPreviousMessages(with error: Error?) {
        guard error == nil else {
            return
        }

        if channelController.hasLoadedAllPreviousMessages {
            messageListVC.headerView = messageListHeaderView
        } else {
            messageListVC.headerView = nil
        }
    }

    override func loadNextMessages(completion: @escaping (Error?) -> Void) {
        messageListVC.footerView = loadingViewIndicator
        super.loadNextMessages(completion: completion)
    }

    override func didFinishLoadingNextMessages(with: Error?) {
        messageListVC.footerView = nil
    }
}
