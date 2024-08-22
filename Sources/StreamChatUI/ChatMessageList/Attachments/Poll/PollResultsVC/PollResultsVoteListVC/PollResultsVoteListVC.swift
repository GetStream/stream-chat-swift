//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The controller that shows all votes of poll option.
open class PollResultsVoteListVC:
    _ViewController,
    ThemeProvider,
    PollVoteListControllerDelegate,
    UITableViewDelegate,
    GroupedSectionListStyling {
    /// The controller that manages the list of votes.
    public var pollVoteListController: PollVoteListController

    /// The poll which the votes belong to.
    public var poll: Poll

    /// The poll option which the votes belong to.
    public var option: PollOption

    public required init(
        pollVoteListController: PollVoteListController,
        poll: Poll,
        option: PollOption
    ) {
        self.pollVoteListController = pollVoteListController
        self.poll = poll
        self.option = option
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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

    // MARK: - Views

    /// The table view responsible to display the poll results.
    open private(set) lazy var tableView = UITableView(frame: .zero, style: .grouped)
        .withoutAutoresizingMaskConstraints

    /// The diffable data source responsible to handle poll updates.
    open private(set) lazy var dataSource = UITableViewDiffableDataSource<PollOption, PollVote>(
        tableView: self.tableView
    ) { [weak self] tableView, indexPath, pollVote in
        self?.reuseCell(tableView, indexPath: indexPath, vote: pollVote)
    }

    /// A component responsible to handle when to load new votes.
    private lazy var viewPaginationHandler: ViewPaginationHandling = {
        ScrollViewPaginationHandler(scrollView: tableView)
    }()

    /// A boolean value that controls whether it is currently loading votes.
    private var isPaginatingVotes = false

    // MARK: - Lifecycle

    override open func setUp() {
        super.setUp()

        tableView.register(components.pollResultsVoteItemCell)
        tableView.register(components.pollResultsSectionHeaderView)

        tableView.estimatedSectionHeaderHeight = 50
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.dataSource = dataSource
        tableView.delegate = self

        pollVoteListController.synchronize()
        pollVoteListController.delegate = self

        viewPaginationHandler.onNewBottomPage = { [weak self] in
            self?.loadMoreVotes()
        }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        tableView.allowsSelection = false
        tableView.backgroundColor = listBackgroundColor
        tableView.separatorStyle = .none
        dataSource.defaultRowAnimation = .fade
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.embed(tableView)
    }

    /// The cell provider implementation of the diffable data source.
    open func reuseCell(
        _ tableView: UITableView,
        indexPath: IndexPath,
        vote: PollVote
    ) -> PollResultsVoteItemCell {
        let cell = tableView.dequeueReusableCell(with: components.pollResultsVoteItemCell, for: indexPath)
        cell.content = .init(vote: vote)
        let isLastItem = pollVoteListController.votes.count == indexPath.item - 1
        style(cell: cell, contentView: cell.itemView, isLastItem: isLastItem)
        return cell
    }

    // MARK: - UITableViewDelegate

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooter(with: components.pollResultsSectionHeaderView)
        view.content = .init(option: option, poll: poll)
        style(sectionHeaderView: view, contentView: view.container, isEmptySection: false)
        return view
    }

    // MARK: - PollVoteListControllerDelegate

    public func controller(_ controller: PollVoteListController, didChangeVotes changes: [ListChange<PollVote>]) {
        var snapshot = NSDiffableDataSourceSnapshot<PollOption, PollVote>()
        snapshot.appendSections([option])
        snapshot.appendItems(Array(controller.votes))
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - Actions

    /// Loads the next page of votes.
    open func loadMoreVotes() {
        guard !isPaginatingVotes && !pollVoteListController.hasLoadedAllVotes else {
            return
        }

        isPaginatingVotes = true
        pollVoteListController.loadMoreVotes { [weak self] error in
            self?.didFinishLoadingMoreVotes(with: error)
        }
    }

    /// Called when loading a new page of votes is finished.
    open func didFinishLoadingMoreVotes(with error: Error?) {
        isPaginatingVotes = false
    }
}
