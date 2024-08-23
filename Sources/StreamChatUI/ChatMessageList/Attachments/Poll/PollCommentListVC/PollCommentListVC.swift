//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view controller that shows the comments/answers of a poll.
open class PollCommentListVC:
    _ViewController,
    ThemeProvider,
    PollVoteListControllerDelegate,
    UITableViewDelegate,
    GroupedSectionListStyling {
    /// The controller that manages the list of comments/answers.
    public var commentsController: PollVoteListController

    /// The controller to handle actions on the Poll.
    public var pollController: PollController

    public required init(
        pollController: PollController,
        commentsController: PollVoteListController
    ) {
        self.commentsController = commentsController
        self.pollController = pollController
        super.init(nibName: nil, bundle: nil)
    }

    /// A convenience initializer that creates the comments controller automatically.
    public required convenience init(pollController: PollController) {
        let commentsController = pollController.client.pollVoteListController(
            query: .init(pollId: pollController.pollId, filter: .equal(.isAnswer, to: true))
        )
        self.init(pollController: pollController, commentsController: commentsController)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The footer view of the table view. By default it displays the button to add a comment.
    open private(set) lazy var footerView: PollCommentListTableFooterView = components
        .pollCommentListTableFooterView.init()

    /// The router object that handles presenting alerts.
    open lazy var alertsRouter: AlertsRouter = components
        .alertsRouter
        .init(rootViewController: self)

    // MARK: - Configuration

    /// Whether the grouped section styling is enabled. By default it is true.
    /// If you want to have a custom look without grouped sections, you should disable this flag.
    open var isGroupedSectionStylingEnabled: Bool {
        true
    }

    /// The background color of the table view.
    open var listBackgroundColor: UIColor {
        appearance.colorPalette.background
    }

    /// The background color for each poll option section.
    open var sectionBackgroundColor: UIColor {
        appearance.colorPalette.background1
    }

    /// The corner radius amount of each section group.
    open var sectionCornerRadius: CGFloat {
        16
    }

    /// The spacing between each section.
    open var sectionSpacing: CGFloat {
        6
    }

    // MARK: - Views

    /// The table view responsible to display the poll results.
    open private(set) lazy var tableView = UITableView(frame: .zero, style: .grouped)
        .withoutAutoresizingMaskConstraints

    /// The diffable data source responsible to handle poll comment updates.
    open private(set) lazy var dataSource = UITableViewDiffableDataSource<PollVote, PollVote>(
        tableView: self.tableView
    ) { [weak self] tableView, indexPath, comment in
        self?.reuseCell(tableView, indexPath: indexPath, comment: comment)
    }

    /// A component responsible to handle when to load new comments.
    private lazy var viewPaginationHandler: ViewPaginationHandling = {
        ScrollViewPaginationHandler(scrollView: tableView)
    }()

    /// A boolean value that controls whether it is currently loading more comments.
    private var isPaginatingComments = false

    // MARK: - Lifecycle

    override open func setUp() {
        super.setUp()

        tableView.register(components.pollCommentListItemCell)
        tableView.register(components.pollCommentListSectionHeaderView)

        tableView.dataSource = dataSource
        tableView.delegate = self

        footerView.onTap = { [weak self] in
            guard let self = self, let poll = self.pollController.poll else { return }
            guard let currentUserId = self.pollController.client.currentUserId else { return }
            let messageId = pollController.messageId
            self.alertsRouter.showPollAddCommentAlert(
                for: poll,
                in: messageId,
                currentUserId: currentUserId
            ) { [weak self] comment in
                self?.pollController.castPollVote(answerText: comment, optionId: nil) { _ in
                    self?.tableView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
                }
            }
        }

        commentsController.synchronize()
        commentsController.delegate = self

        viewPaginationHandler.onNewBottomPage = { [weak self] in
            self?.loadMoreComments()
        }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        title = L10n.Polls.commentsTitle
        tableView.allowsSelection = false
        tableView.backgroundColor = listBackgroundColor
        tableView.separatorStyle = .none
        tableView.sectionFooterHeight = sectionSpacing
        dataSource.defaultRowAnimation = .fade
        style(tableFooterView: footerView, contentView: footerView.container)
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.embed(tableView)
        tableView.tableFooterView = footerView
        tableView.layoutIfNeeded()
    }

    /// The cell provider implementation of the diffable data source.
    open func reuseCell(
        _ tableView: UITableView,
        indexPath: IndexPath,
        comment: PollVote
    ) -> PollCommentListItemCell {
        let cell = tableView.dequeueReusableCell(with: components.pollCommentListItemCell, for: indexPath)
        cell.content = .init(comment: comment)
        style(cell: cell, contentView: cell.itemView, isLastItem: true)
        return cell
    }

    // MARK: - UITableViewDelegate

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !commentsController.votes.isEmpty else {
            return nil
        }

        let view = tableView.dequeueReusableHeaderFooter(with: components.pollCommentListSectionHeaderView)
        let comment = commentsController.votes[section]
        view.content = .init(comment: comment)
        style(sectionHeaderView: view, contentView: view.container, isEmptySection: false)
        return view
    }

    // MARK: - PollVoteListControllerDelegate

    public func controller(_ controller: PollVoteListController, didChangeVotes changes: [ListChange<PollVote>]) {
        var snapshot = NSDiffableDataSourceSnapshot<PollVote, PollVote>()
        let comments = Array(controller.votes)
        snapshot.appendSections(comments)
        comments.forEach {
            snapshot.appendItems([$0], toSection: $0)
        }
        dataSource.apply(snapshot, animatingDifferences: true)

        if let poll = pollController.poll, let currentUserId = pollController.client.currentUserId {
            footerView.content = .init(poll: poll, currentUserId: currentUserId)
        }
    }

    // MARK: - Actions

    /// Loads the next page of comments.
    open func loadMoreComments() {
        guard !isPaginatingComments && !commentsController.hasLoadedAllVotes else {
            return
        }

        isPaginatingComments = true
        commentsController.loadMoreVotes { [weak self] error in
            self?.didFinishLoadingMoreComments(with: error)
        }
    }

    /// Called when loading a new page of comments is finished.
    open func didFinishLoadingMoreComments(with error: Error?) {
        isPaginatingComments = false
    }
}
