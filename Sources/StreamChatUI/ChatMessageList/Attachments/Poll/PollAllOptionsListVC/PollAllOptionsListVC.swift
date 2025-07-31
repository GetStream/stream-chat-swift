//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view controller that shows all the options in a poll.
open class PollAllOptionsListVC:
    _ViewController,
    ThemeProvider,
    PollControllerDelegate,
    UITableViewDataSource,
    UITableViewDelegate {
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

    // MARK: - Views

    /// The table view responsible to display the poll results.
    open private(set) lazy var tableView = UITableView(frame: .zero, style: .insetGrouped)
        .withoutAutoresizingMaskConstraints

    /// A feedbackGenerator that will be used to provide feedback when a task is successful or not.
    /// You can disable the feedback generator by overriding to `nil`.
    open private(set) lazy var notificationFeedbackGenerator: UINotificationFeedbackGenerator? = UINotificationFeedbackGenerator()

    public struct Section: RawRepresentable, Equatable, Sendable {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        /// The section that displays the poll's name.
        public static let name = Self(rawValue: "name")

        /// The section that displays the options of the poll.
        public static let options = Self(rawValue: "options")
    }

    /// The sections of the view.
    public var sections: [Section] = [
        .name,
        .options
    ]

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

        tableView.register(PollAllOptionsListItemCell.self)

        tableView.tableHeaderView = UIView(frame: .zero)
        tableView.rowHeight = 56
        tableView.dataSource = self
        tableView.delegate = self

        pollController.synchronize()
        pollController.delegate = self
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        title = L10n.Polls.allOptionsTitle
        tableView.allowsSelection = true
        tableView.backgroundColor = appearance.colorPalette.background
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 24
        tableView.separatorStyle = .none
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.embed(tableView)
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate

    public func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .name:
            return 1
        case .options:
            return pollController.poll?.options.count ?? 0
        default:
            return 0
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section] {
        case .name:
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            cell.backgroundColor = appearance.colorPalette.background1
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = pollController.poll?.name
            cell.textLabel?.textColor = appearance.colorPalette.text
            return cell
        case .options:
            let cell = tableView.dequeueReusableCell(with: PollAllOptionsListItemCell.self, for: indexPath)
            let options = pollController.poll?.options ?? []
            let option = options[indexPath.item]
            if let poll = pollController.poll {
                cell.content = .init(option: option, poll: poll)
            }
            return cell
        default:
            return UITableViewCell()
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sections[indexPath.section] {
        case .name:
            break
        case .options:
            guard pollController.poll?.isClosed == false else { return }
            let options = pollController.poll?.options ?? []
            let option = options[indexPath.item]
            togglePollVote(for: option)
        default:
            break
        }
    }

    // MARK: Actions

    @objc open func didTapCloseButton(sender: Any?) {
        dismiss(animated: true)
    }

    /// Casts or removes the vote for the given option depending on the current state.
    open func togglePollVote(for option: PollOption) {
        notificationFeedbackGenerator?.notificationOccurred(.success)
        if let currentUserVote = pollController.poll?.currentUserVote(for: option) {
            pollController.removePollVote(voteId: currentUserVote.id) { [weak self] error in
                if error != nil {
                    self?.notificationFeedbackGenerator?.notificationOccurred(.error)
                }
            }
        } else {
            pollController.castPollVote(answerText: nil, optionId: option.id) { [weak self] error in
                if error != nil {
                    self?.notificationFeedbackGenerator?.notificationOccurred(.error)
                }
            }
        }
    }

    // MARK: - PollControllerDelegate

    open func pollController(_ pollController: PollController, didUpdatePoll poll: EntityChange<Poll>) {
        tableView.reloadData()
    }

    open func pollController(
        _ pollController: PollController,
        didUpdateCurrentUserVotes votes: [ListChange<PollVote>]
    ) {
        // no-op
    }
}
