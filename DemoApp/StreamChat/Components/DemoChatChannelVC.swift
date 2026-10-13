//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

    lazy var loadingViewIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.frame = .init(x: 0, y: 0, width: 50, height: 50)
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
        updateBackButton()

        channelAvatarView.isUserInteractionEnabled = true
        channelAvatarView.isAccessibilityElement = true
        channelAvatarView.accessibilityTraits = .button
        channelAvatarView.accessibilityLabel = "Channel info"
        channelAvatarView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(channelAvatarTapped))
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBackButton()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        updateBackButton()
    }

    private lazy var customBackButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward"),
            style: .plain,
            target: self,
            action: #selector(goBack)
        )
        button.accessibilityLabel = "Back"
        // Devices that place a bar on a vertical edge, like a foldable, host navigation items
        // there rather than in the navigation bar. The axis behavior ships with the iOS 27.1
        // SDK, so the check on the underlying UIKit module keeps the app compiling with Xcode
        // versions that do not know about it yet.
        #if canImport(UIKit, _underlyingVersion: 9127.0.85)
        if #available(iOS 27.1, *) {
            button.axisBehavior = .verticalPreferred
        }
        #endif
        return button
    }()

    private func updateBackButton() {
        // The iPad detail column is the root of its navigation controller, so pop would do nothing.
        let canPop = navigationController.map { $0.viewControllers.first !== self } ?? false
        navigationItem.leftBarButtonItem = canPop ? customBackButton : nil
        let popGesture = navigationController?.interactivePopGestureRecognizer
        if canPop {
            popGesture?.delegate = self
        } else if popGesture?.delegate === self {
            popGesture?.delegate = nil
        }
    }

    @objc private func channelAvatarTapped() {
        guard let cid = channelController.cid else { return }

        let channelInfoVC = DemoChatChannelInfoVC(cid: cid, client: channelController.client)
        show(channelInfoVC, sender: self)
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

    override func loadPreviousMessages(completion: @escaping @MainActor (Error?) -> Void) {
        messageListVC.headerView = loadingViewIndicator
        super.loadPreviousMessages(completion: completion)
    }

    override func didFinishLoadingPreviousMessages(with error: Error?) {
        messageListVC.headerView = nil
    }

    override func loadNextMessages(completion: @escaping @MainActor (Error?) -> Void) {
        messageListVC.footerView = loadingViewIndicator
        super.loadNextMessages(completion: completion)
    }

    override func didFinishLoadingNextMessages(with: Error?) {
        messageListVC.footerView = nil
    }
}
