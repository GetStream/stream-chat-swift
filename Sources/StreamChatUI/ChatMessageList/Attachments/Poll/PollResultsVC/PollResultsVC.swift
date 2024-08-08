//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view controller that shows the results of a poll.
open class PollResultsVC:
    _ViewController,
    ThemeProvider,
    PollControllerDelegate,
    UITableViewDelegate {
    /// The controller that manages the poll data.
    public var pollController: PollController

    public required init(pollController: PollController) {
        self.pollController = pollController
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: - Configuration

    /// The maximum votes displayed per option.
    public var maximumVotesPerOption: Int = 5

    /// The corner radius amount of each section group.
    public var sectionCornerRadius: CGFloat = 16

    /// The spacing between each section.
    public var sectionSpacing: CGFloat = 8

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

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        tableView.register(components.pollResultsOptionHeaderView)
        tableView.register(components.pollResultsFooterButtonView)

        tableView.estimatedSectionHeaderHeight = 50
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.dataSource = dataSource
        tableView.delegate = self

        pollController.synchronize()
        pollController.delegate = self
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        title = L10n.Message.Polls.resultsTitle
        tableView.allowsSelection = false
        tableView.backgroundColor = appearance.colorPalette.background
        tableView.separatorStyle = .none
        dataSource.defaultRowAnimation = .fade
        headerView.container.layer.cornerRadius = sectionCornerRadius
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
        poll.options.forEach { option in
            let latestVotes = option.latestVotes
                .sorted(by: { $0.createdAt < $1.createdAt })
                .suffix(maximumVotesPerOption)

            snapshot.appendItems(Array(latestVotes), toSection: option)
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
        guard let option = pollController.poll?.options[indexPath.section] else {
            return cell
        }
        cell.content = .init(vote: vote)
        let isLastItem = indexPath.row == option.latestVotes.count - 1
        if isLastItem {
            cell.itemView.layer.cornerRadius = sectionCornerRadius
            cell.itemView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        } else {
            cell.itemView.layer.cornerRadius = 0
            cell.itemView.layer.maskedCorners = []
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let poll = pollController.poll else { return nil }
        let option = poll.options[section]
        let view = tableView.dequeueReusableHeaderFooter(with: components.pollResultsOptionHeaderView)
        view.content = .init(option: option, poll: poll)
        view.optionView.layer.cornerRadius = sectionCornerRadius
        if !option.latestVotes.isEmpty {
            view.optionView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            view.optionView.layer.maskedCorners = .all
        }
        return view
    }

    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let option = pollController.poll?.options[section],
              option.latestVotes.count > maximumVotesPerOption else {
            return nil
        }
        let view = tableView.dequeueReusableHeaderFooter(with: components.pollResultsFooterButtonView)
        view.onTap = {
            print(option)
        }
        view.container.layer.cornerRadius = sectionCornerRadius
        view.container.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
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

    open func pollController(_ pollController: PollController, didUpdatePoll poll: EntityChange<Poll>) {
        updateDataSource()
    }

    open func pollController(
        _ pollController: PollController,
        didUpdateCurrentUserVotes votes: [ListChange<PollVote>]
    ) {
        // no-op
    }
}
