//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view controller that shows the results of a poll.
open class PollResultsVC:
    _ViewController,
    ThemeProvider,
    PollControllerDelegate,
    UITableViewDelegate,
    GroupedSectionListStyling {
    /// The controller that manages the poll data.
    public var pollController: PollController

    public required init(pollController: PollController) {
        self.pollController = pollController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    /// The maximum votes displayed per option.
    open var maximumVotesPerOption: Int {
        5
    }

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
        8
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

    /// The header view of the table view. By default it displays the poll's name.
    open private(set) lazy var headerView: PollResultsTableHeaderView = components
        .pollResultsTableHeaderView.init()

    // MARK: - Lifecycle

    override open func setUp() {
        super.setUp()

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: appearance.images.close,
            style: .done,
            target: self,
            action: #selector(didTapCloseButton(sender:))
        )
        navigationItem.leftBarButtonItem?.tintColor = appearance.colorPalette.background7

        tableView.register(components.pollResultsVoteItemCell)
        tableView.register(components.pollResultsSectionHeaderView)
        tableView.register(components.pollResultsSectionFooterView)

        tableView.estimatedSectionHeaderHeight = 50
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.dataSource = dataSource
        tableView.delegate = self

        pollController.synchronize()
        pollController.delegate = self
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        title = L10n.Polls.resultsTitle
        tableView.allowsSelection = false
        tableView.backgroundColor = listBackgroundColor
        tableView.separatorStyle = .none
        dataSource.defaultRowAnimation = .fade
        style(tableHeaderView: headerView, contentView: headerView.container)
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.embed(tableView)
        tableView.tableHeaderView = headerView
        tableView.layoutIfNeeded()
    }

    @objc open func didTapCloseButton(sender: Any?) {
        dismiss(animated: true)
    }

    // MARK: - Data Source Handling

    /// Applies data source changes to the table view based on the current poll controller data.
    open func updateDataSource() {
        guard let poll = pollController.poll else { return }
        guard !poll.options.isEmpty else {
            return
        }

        headerView.content = .init(poll: poll)

        var snapshot = NSDiffableDataSourceSnapshot<PollOption, PollVote>()
        snapshot.appendSections(poll.options)
       
        if poll.votingVisibility != .anonymous {
            poll.options.forEach { option in
                let latestVotes = option.latestVotes
                    .sorted(by: { $0.createdAt > $1.createdAt })
                    .prefix(maximumVotesPerOption)

                snapshot.appendItems(Array(latestVotes), toSection: option)
            }
        }

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    /// The cell provider implementation of the diffable data source.
    open func reuseCell(
        _ tableView: UITableView,
        indexPath: IndexPath,
        vote: PollVote
    ) -> PollResultsVoteItemCell {
        let cell = tableView.dequeueReusableCell(with: components.pollResultsVoteItemCell, for: indexPath)
        guard let option = pollController.poll?.options[safe: indexPath.section],
              let poll = pollController.poll else {
            return cell
        }
        cell.content = .init(vote: vote, poll: poll)
        let isLastItem = indexPath.row == option.latestVotes.count - 1
        style(cell: cell, contentView: cell.itemView, isLastItem: isLastItem)
        return cell
    }

    // MARK: - UITableViewDelegate

    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let poll = pollController.poll,
              let option = poll.options[safe: section] else {
            return nil
        }
        let view = tableView.dequeueReusableHeaderFooter(with: components.pollResultsSectionHeaderView)
        view.content = .init(option: option, poll: poll)
        let isEmptySection = option.latestVotes.isEmpty || poll.votingVisibility == .anonymous
        style(sectionHeaderView: view, contentView: view.container, isEmptySection: isEmptySection)
        return view
    }

    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let option = pollController.poll?.options[section],
              option.latestVotes.count > maximumVotesPerOption else {
            return nil
        }
        let view = tableView.dequeueReusableHeaderFooter(with: components.pollResultsSectionFooterView)
        view.onTap = { [weak self] in
            self?.showVoteList(for: option)
        }
        view.bottomSpacing = sectionSpacing
        style(sectionFooterView: view, contentView: view.container)
        return view
    }

    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let option = pollController.poll?.options[section],
              option.latestVotes.count > maximumVotesPerOption else {
            return sectionSpacing
        }
        return UITableView.automaticDimension
    }

    // MARK: - PollControllerDelegate

    nonisolated open func pollController(_ pollController: PollController, didUpdatePoll poll: EntityChange<Poll>) {
        MainActor.ensureIsolated {
            updateDataSource()
        }
    }

    nonisolated open func pollController(
        _ pollController: PollController,
        didUpdateCurrentUserVotes votes: [ListChange<PollVote>]
    ) {
        // no-op
    }

    // MARK: - Navigation

    open func showVoteList(for option: PollOption) {
        guard let poll = pollController.poll else { return }
        let query = PollVoteListQuery(
            pollId: pollController.pollId,
            optionId: option.id,
            pagination: .init(pageSize: 25)
        )
        let voteListController = pollController.client.pollVoteListController(query: query)
        let viewController = components.pollResultsVoteListVC.init(
            pollVoteListController: voteListController,
            poll: poll,
            option: option
        )
        navigationController?.pushViewController(viewController, animated: true)
    }
}
