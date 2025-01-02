//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class SlackChatMessageListViewController: ChatMessageListVC {
    override func cellContentClassForMessage(at indexPath: IndexPath) -> ChatMessageContentView.Type {
        SlackChatMessageContentView.self
    }

    override func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: listView)
        guard gesture.state == .began,
              let indexPath = listView.indexPathForRow(at: location),
              let cell = listView.cellForRow(at: indexPath) as? ChatMessageCell,
              let messageContentView = cell.messageContentView as? SlackChatMessageContentView,
              let message = messageContentView.content else {
            return super.handleLongPress(gesture)
        }

        let reactionsLocation = gesture.location(in: messageContentView.slackReactionsView.collectionView)
        guard let reactionsIndexPath = messageContentView.slackReactionsView.collectionView.indexPathForItem(at: reactionsLocation) else {
            return super.handleLongPress(gesture)
        }
        
        let reaction = messageContentView.slackReactionsView.reactions[reactionsIndexPath.row]
        openReactionsSheet(for: message, with: reaction.type)
    }

    func openReactionsSheet(for message: ChatMessage, with reactionType: MessageReactionType) {
        let reactionListController = client.reactionListController(
            query: .init(
                messageId: message.id,
                filter: .equal(.reactionType, to: reactionType)
            )
        )
        let slackReactionListView = SlackReactionListViewController(
            reactionListController: reactionListController
        )
        present(slackReactionListView, animated: true)
    }
}

/// Displays the reaction authors for a specific reaction type.
class SlackReactionListViewController: UITableViewController, ChatReactionListControllerDelegate {
    let reactionListController: ChatReactionListController

    init(reactionListController: ChatReactionListController) {
        self.reactionListController = reactionListController
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var reactions: [ChatMessageReaction] = []

    private var isLoadingReactions: Bool = false

    let prefetchThreshold: Int = 10

    override func viewDidLoad() {
        super.viewDidLoad()

        if let sheetController = presentationController as? UISheetPresentationController {
            sheetController.detents = [.medium(), .large()]
            sheetController.prefersGrabberVisible = true
        }

        reactionListController.delegate = self
        isLoadingReactions = true
        reactionListController.synchronize { [weak self] _ in
            self?.isLoadingReactions = false
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        reactions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reaction = reactions[indexPath.row]
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "slack-reaction-cell")
        cell.detailTextLabel?.text = reaction.author.name ?? "Unknown"
        cell.textLabel?.text = reaction.type.toEmoji()
        return cell
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        prefetchNextReactions(currentIndexPath: indexPath)
    }

    func prefetchNextReactions(currentIndexPath indexPath: IndexPath) {
        if isLoadingReactions {
            return
        }

        if indexPath.row > reactions.count - prefetchThreshold {
            return
        }

        isLoadingReactions = true
        reactionListController.loadMoreReactions { [weak self] _ in
            self?.isLoadingReactions = false
        }
    }

    func controller(_ controller: ChatReactionListController, didChangeReactions changes: [ListChange<ChatMessageReaction>]) {
        reactions = Array(controller.reactions)
        tableView.reloadData()
    }
}
