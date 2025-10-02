//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

class DemoChatThreadVC: ChatThreadVC, CurrentChatUserControllerDelegate {
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

    var thread: ChatThread?

    override func viewDidLoad() {
        super.viewDidLoad()

        let debugButton = UIBarButtonItem(
            image: UIImage(systemName: "ladybug.fill")!,
            style: .plain,
            target: self,
            action: #selector(debugTap)
        )
        navigationItem.rightBarButtonItems = [debugButton]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        thread = messageController.dataStore.thread(parentMessageId: messageController.messageId)
    }

    @objc private func debugTap() {
        presentAlert(title: "Select an action", actions: [
            .init(title: "Update thread title", style: .default, handler: { [unowned self] _ in
                self.presentAlert(title: "Enter thread title", textFieldPlaceholder: "Thread title") { title in
                    guard let title = title, !title.isEmpty else {
                        self.presentAlert(title: "Title is not valid")
                        return
                    }
                    self.messageController.updateThread(title: title) { [weak self] result in
                        self?.thread = try? result.get()
                    }
                }
            }),
            .init(title: "Show thread info", style: .default, handler: { [unowned self] _ in
                self.present(DebugObjectViewController(object: thread), animated: true)
            }),
            .init(title: "Load newest thread info", style: .default, handler: { [unowned self] _ in
                self.messageController.loadThread { [weak self] result in
                    self?.thread = try? result.get()
                    self?.present(DebugObjectViewController(object: self?.thread), animated: true)
                }
            })
        ])
    }

    // MARK: - Dismissing the thread if the root message was hard deleted.

    override func eventsController(_ controller: EventsController, didReceiveEvent event: any Event) {
        super.eventsController(controller, didReceiveEvent: event)

        // Dismiss the thread if the root message was hard deleted.
        if let event = event as? MessageDeletedEvent, event.isHardDelete, event.message.id == messageController.messageId {
            navigationController?.popViewController(animated: true)
        }
    }

    // MARK: - Loading previous and next messages state handling.

    override func loadPreviousReplies(completion: @escaping @MainActor (Error?) -> Void) {
        messageListVC.headerView = loadingViewIndicator
        super.loadPreviousReplies(completion: completion)
    }

    override func didFinishLoadingPreviousReplies(with error: Error?) {
        messageListVC.headerView = nil
    }

    override func loadNextReplies(completion: @escaping @MainActor (Error?) -> Void) {
        messageListVC.footerView = loadingViewIndicator
        super.loadNextReplies(completion: completion)
    }

    override func didFinishLoadingNextReplies(with error: Error?) {
        messageListVC.footerView = nil
    }
}
