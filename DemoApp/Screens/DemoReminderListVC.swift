//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

class DemoReminderListVC: UIViewController, ThemeProvider {
    var onLogout: (() -> Void)?
    var onDisconnect: (() -> Void)?

    private let currentUserController: CurrentChatUserController

    private var activeController: MessageReminderListController
    private var reminders: [MessageReminder] = []
    private var isPaginatingReminders = false

    private lazy var allRemindersController = FilterOption.all.makeController(client: currentUserController.client)
    private lazy var upcomingRemindersController = FilterOption.upcoming.makeController(client: currentUserController.client)
    private lazy var scheduledRemindersController = FilterOption.scheduled.makeController(client: currentUserController.client)
    private lazy var laterRemindersController = FilterOption.later.makeController(client: currentUserController.client)
    private lazy var overdueRemindersController = FilterOption.overdue.makeController(client: currentUserController.client)

    private lazy var eventsController = currentUserController.client.eventsController()

    // Timer for refreshing due dates on cells
    private var refreshTimer: Timer?
    
    // Filter options
    enum FilterOption: Int, CaseIterable {
        case all, overdue, upcoming, scheduled, later

        var title: String {
            switch self {
            case .all: return "All"
            case .scheduled: return "Scheduled"
            case .overdue: return "Overdue"
            case .upcoming: return "Upcoming"
            case .later: return "Saved for later"
            }
        }

        var query: MessageReminderListQuery {
            switch self {
            case .all:
                return MessageReminderListQuery()
            case .scheduled:
                return MessageReminderListQuery(
                    filter: .withRemindAt,
                    sort: [.init(key: .remindAt, isAscending: true)]
                )
            case .later:
                return MessageReminderListQuery(
                    filter: .withoutRemindAt,
                    sort: [.init(key: .createdAt, isAscending: false)]
                )
            case .overdue:
                return MessageReminderListQuery(
                    filter: .overdue,
                    sort: [.init(key: .remindAt, isAscending: false)]
                )
            case .upcoming:
                return MessageReminderListQuery(
                    filter: .upcoming,
                    sort: [.init(key: .remindAt, isAscending: true)]
                )
            }
        }

        func makeController(client: ChatClient) -> MessageReminderListController {
            client.messageReminderListController(query: query)
        }
    }
    
    private var selectedFilter: FilterOption = .all {
        didSet {
            if oldValue != selectedFilter {
                switchToController(for: selectedFilter)
                updateFilterPills()
            }
        }
    }
    
    lazy var userAvatarView: CurrentChatUserAvatarView = components
        .currentUserAvatarView.init()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DemoReminderCell.self, forCellReuseIdentifier: "DemoReminderCell")
        return tableView
    }()
    
    private lazy var filtersScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return scrollView
    }()
    
    private lazy var filtersStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        return stackView
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = Appearance.default.colorPalette.subtitleText
        label.font = Appearance.default.fonts.body
        return label
    }()

    private lazy var emptyStateImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "bell.slash"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = Appearance.default.colorPalette.subtitleText
        return imageView
    }()

    private lazy var emptyStateView: UIView = {
        VContainer(spacing: 12, alignment: .center) {
            emptyStateImageView
                .width(48)
                .height(48)
            emptyStateLabel
        }
    }()
    
    init(currentUserController: CurrentChatUserController) {
        self.currentUserController = currentUserController
        activeController = currentUserController.client.messageReminderListController()

        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Reminders"

        eventsController.delegate = self

        userAvatarView.controller = currentUserController
        userAvatarView.addTarget(self, action: #selector(didTapOnCurrentUserAvatar), for: .touchUpInside)
        userAvatarView.translatesAutoresizingMaskIntoConstraints = false
        
        navigationItem.backButtonTitle = ""
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: userAvatarView)
        
        setupViews()
        setupFilterPills()
        updateEmptyStateMessage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadReminders()
        startRefreshTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRefreshTimer()
    }
    
    private func startRefreshTimer() {
        // Cancel any existing timer first
        stopRefreshTimer()
        
        // Create a new timer that fires every 60 seconds
        refreshTimer = Timer.scheduledTimer(
            timeInterval: 60.0,
            target: self,
            selector: #selector(refreshVisibleCells),
            userInfo: nil,
            repeats: true
        )
        
        // Add to RunLoop to ensure it works while scrolling
        if let timer = refreshTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    @objc private func refreshVisibleCells() {
        // Only refresh visible cells to avoid unnecessary work
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows else { return }
        
        for indexPath in visibleIndexPaths {
            if indexPath.row < reminders.count,
               let cell = tableView.cellForRow(at: indexPath) as? DemoReminderCell {
                let reminder = reminders[indexPath.row]
                cell.configure(with: reminder)
            }
        }
    }
    
    private func setupViews() {
        view.backgroundColor = Appearance.default.colorPalette.background
        tableView.backgroundColor = Appearance.default.colorPalette.background

        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 50))
        headerView.backgroundColor = Appearance.default.colorPalette.background
        headerView.addSubview(filtersScrollView)
        filtersScrollView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            filtersScrollView.topAnchor.constraint(equalTo: headerView.topAnchor),
            filtersScrollView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            filtersScrollView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            filtersScrollView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])
        
        filtersScrollView.addSubview(filtersStackView)
        NSLayoutConstraint.activate([
            filtersStackView.topAnchor.constraint(equalTo: filtersScrollView.topAnchor),
            filtersStackView.leadingAnchor.constraint(equalTo: filtersScrollView.leadingAnchor),
            filtersStackView.trailingAnchor.constraint(equalTo: filtersScrollView.trailingAnchor),
            filtersStackView.bottomAnchor.constraint(equalTo: filtersScrollView.bottomAnchor),
            filtersStackView.heightAnchor.constraint(equalTo: filtersScrollView.heightAnchor)
        ])

        view.addSubview(tableView)
        tableView.tableHeaderView = headerView
        tableView.addSubview(emptyStateView)
        tableView.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyStateView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            emptyStateView.heightAnchor.constraint(equalToConstant: 100),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update header view width when view size changes
        if let headerView = tableView.tableHeaderView {
            let width = tableView.bounds.width
            var frame = headerView.frame
            
            // Only update if width changed
            if frame.width != width {
                frame.size.width = width
                headerView.frame = frame
                tableView.tableHeaderView = headerView
            }
        }
    }
    
    private func setupFilterPills() {
        for filterOption in FilterOption.allCases {
            let pillButton = createFilterPillButton(for: filterOption)
            filtersStackView.addArrangedSubview(pillButton)
        }
        updateFilterPills()
    }
    
    private func createFilterPillButton(for filterOption: FilterOption) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = filterOption.rawValue
        button.setTitle(filterOption.title, for: .normal)
        button.titleLabel?.font = Appearance.default.fonts.footnote
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        button.addTarget(self, action: #selector(didTapFilterPill), for: .touchUpInside)
        return button
    }
    
    private func updateFilterPills() {
        for subview in filtersStackView.arrangedSubviews {
            guard let button = subview as? UIButton else { continue }
            
            if button.tag == selectedFilter.rawValue {
                button.backgroundColor = Appearance.default.colorPalette.accentPrimary
                button.setTitleColor(.white, for: .normal)
            } else {
                button.backgroundColor = Appearance.default.colorPalette.background2
                button.setTitleColor(Appearance.default.colorPalette.text, for: .normal)
            }
        }
        
        // Update empty state message when filter changes
        updateEmptyStateMessage()
    }
    
    private func updateEmptyStateMessage() {
        switch selectedFilter {
        case .all:
            emptyStateLabel.text = "No reminders"
            emptyStateImageView.image = UIImage(systemName: "bell.slash")
        case .scheduled:
            emptyStateLabel.text = "No scheduled reminders"
            emptyStateImageView.image = UIImage(systemName: "bell.slash")
        case .later:
            emptyStateLabel.text = "No saved for later"
            emptyStateImageView.image = UIImage(systemName: "bookmark.slash")
        case .overdue:
            emptyStateLabel.text = "No overdue reminders"
            emptyStateImageView.image = UIImage(systemName: "bell.slash")
        case .upcoming:
            emptyStateLabel.text = "No upcoming reminders"
            emptyStateImageView.image = UIImage(systemName: "bell.slash")
        }
    }
    
    @objc private func didTapFilterPill(_ sender: UIButton) {
        guard let filterOption = FilterOption(rawValue: sender.tag) else { return }
        selectedFilter = filterOption
    }
    
    private func switchToController(for filter: FilterOption) {
        switch filter {
        case .all:
            activeController = allRemindersController
        case .overdue:
            activeController = overdueRemindersController
        case .upcoming:
            activeController = upcomingRemindersController
        case .scheduled:
            activeController = scheduledRemindersController
        case .later:
            activeController = laterRemindersController
        }
        activeController.delegate = self

        // Only load reminders if this controller hasn't loaded any yet
        if activeController.reminders.isEmpty && !activeController.hasLoadedAllReminders {
            loadReminders()
        } else {
            // Otherwise just update the UI with existing data
            updateRemindersData()
        }
    }

    private func loadReminders() {
        let controller = activeController
        controller.delegate = self
        
        if reminders.isEmpty {
            loadingIndicator.startAnimating()
            emptyStateView.isHidden = true
        }
        
        controller.synchronize { [weak self] _ in
            self?.loadingIndicator.stopAnimating()
            self?.updateRemindersData()
        }
    }
    
    private func loadMoreReminders() {
        let controller = activeController
        guard !isPaginatingReminders && !controller.hasLoadedAllReminders else {
            return
        }

        isPaginatingReminders = true
        controller.loadMoreReminders { [weak self] _ in
            self?.isPaginatingReminders = false
        }
    }

    @objc private func didTapOnCurrentUserAvatar(_ sender: Any) {
        presentUserOptionsAlert(
            onLogout: onLogout,
            onDisconnect: onDisconnect,
            client: currentUserController.client
        )
    }
    
    private func showEditReminderOptions(for reminder: MessageReminder, at indexPath: IndexPath) {
        let alert = UIAlertController(title: "Edit Reminder", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Remind in 1 Minutes", style: .default) { [weak self] _ in
            let date = Date().addingTimeInterval(1.05 * 60)
            self?.updateReminderDate(for: reminder, newDate: date)
        })

        alert.addAction(UIAlertAction(title: "Remind in 1 Hour", style: .default) { [weak self] _ in
            let date = Date().addingTimeInterval(60 * 60)
            self?.updateReminderDate(for: reminder, newDate: date)
        })

        alert.addAction(UIAlertAction(title: "Remind tomorrow", style: .default) { [weak self] _ in
            let date = Date().addingTimeInterval(24 * 60 * 60)
            self?.updateReminderDate(for: reminder, newDate: date)
        })

        alert.addAction(UIAlertAction(title: "Clear due date", style: .default) { [weak self] _ in
            self?.updateReminderDate(for: reminder, newDate: nil)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverController = alert.popoverPresentationController {
            if let cell = tableView.cellForRow(at: indexPath) {
                popoverController.sourceView = cell
                popoverController.sourceRect = cell.bounds
            }
        }
        
        present(alert, animated: true)
    }
    
    private func updateReminderDate(for reminder: MessageReminder, newDate: Date?) {
        let messageController = currentUserController.client.messageController(
            cid: reminder.channel.cid,
            messageId: reminder.message.id
        )
        
        messageController.updateReminder(remindAt: newDate)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func updateRemindersData() {
        reminders = Array(activeController.reminders)
        tableView.reloadData()
        updateEmptyStateMessage()
        emptyStateView.isHidden = !reminders.isEmpty
    }
}

// MARK: - MessageReminderListControllerDelegate

extension DemoReminderListVC: MessageReminderListControllerDelegate, EventsControllerDelegate {
    func controller(
        _ controller: MessageReminderListController,
        didChangeReminders changes: [ListChange<MessageReminder>]
    ) {
        // Only update UI if this is the active controller
        guard controller === activeController else { return }
        updateRemindersData()
    }

    func eventsController(_ controller: EventsController, didReceiveEvent event: any Event) {
        if event is MessageReminderDueEvent {
            updateReminderListsWithNewNowDate()
        }
    }

    /// Update the reminder lists with the new current date.
    /// When the controllers are created, they use the current date to query the reminders.
    /// When a reminder is due, we need to re-create the queries with the new current date.
    /// Otherwise, the reminders will not be updated since the current date will be outdated.
    private func updateReminderListsWithNewNowDate() {
        upcomingRemindersController = FilterOption.upcoming.makeController(client: currentUserController.client)
        overdueRemindersController = FilterOption.overdue.makeController(client: currentUserController.client)
        scheduledRemindersController = FilterOption.scheduled.makeController(client: currentUserController.client)
        if selectedFilter == .upcoming {
            activeController = upcomingRemindersController
        } else if selectedFilter == .overdue {
            activeController = overdueRemindersController
        } else if selectedFilter == .scheduled {
            activeController = scheduledRemindersController
        } else {
            return
        }
        activeController.delegate = self
        updateRemindersData()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension DemoReminderListVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        reminders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DemoReminderCell", for: indexPath) as? DemoReminderCell
        let reminder = reminders[indexPath.row]
        cell?.configure(with: reminder)
        return cell ?? .init()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Only react to table view scrolling, not the filter scroll view
        guard scrollView == tableView else { return }
        
        let threshold: CGFloat = 100
        let contentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        if maximumOffset - contentOffset <= threshold {
            loadMoreReminders()
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let reminder = reminders[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self = self else { return }
            
            let messageController = self.currentUserController.client.messageController(
                cid: reminder.channel.cid,
                messageId: reminder.message.id
            )
            
            messageController.deleteReminder { error in
                if let error = error {
                    self.showErrorAlert(message: "Failed to delete reminder: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, completion in
            guard let self = self else { return }
            self.showEditReminderOptions(for: reminder, at: indexPath)
            completion(true)
        }
        editAction.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let reminder = reminders[indexPath.row]
        let channelController = currentUserController.client.channelController(
            for: ChannelQuery(
                cid: reminder.channel.cid,
                paginationParameter: .around(reminder.message.id)
            )
        )

        let channelVC = DemoChatChannelVC()
        channelVC.channelController = channelController
        navigationController?.pushViewController(channelVC, animated: true)
    }
}

// MARK: - Reminder Cell

class DemoReminderCell: UITableViewCell {
    private let channelNameLabel: UILabel = {
        let label = UILabel()
        label.font = Appearance.default.fonts.bodyBold
        label.textColor = Appearance.default.colorPalette.text
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = Appearance.default.fonts.footnote
        label.numberOfLines = 2
        label.textColor = Appearance.default.colorPalette.subtitleText
        return label
    }()
    
    private let dueDateContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        return view
    }()
    
    private let dueDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Appearance.default.fonts.footnoteBold
        label.textColor = Appearance.default.colorPalette.staticColorText
        label.textAlignment = .center
        return label
    }()

    private let saveForLaterIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "bookmark.fill"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = Appearance.default.colorPalette.accentPrimary
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = Appearance.default.colorPalette.background
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        dueDateContainer.addSubview(dueDateLabel)
        dueDateContainer.setContentCompressionResistancePriority(.required, for: .horizontal)
        dueDateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        messageLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        NSLayoutConstraint.activate([
            dueDateLabel.topAnchor.constraint(equalTo: dueDateContainer.topAnchor, constant: 4),
            dueDateLabel.leadingAnchor.constraint(equalTo: dueDateContainer.leadingAnchor, constant: 8),
            dueDateLabel.trailingAnchor.constraint(equalTo: dueDateContainer.trailingAnchor, constant: -8),
            dueDateLabel.bottomAnchor.constraint(equalTo: dueDateContainer.bottomAnchor, constant: -4)
        ])
        
        VContainer(spacing: 8) {
            HContainer(spacing: 4) {
                channelNameLabel
                Spacer()
                saveForLaterIconView
                dueDateContainer
            }
            messageLabel
                .height(20)
        }.embed(
            in: contentView,
            insets: .init(top: 8, leading: 16, bottom: 8, trailing: 16)
        )
    }
    
    func configure(with reminder: MessageReminder) {
        let channelName = Appearance.default.formatters.channelName.format(
            channel: reminder.channel,
            forCurrentUserId: StreamChatWrapper.shared.client?.currentUserId
        ) ?? ""
        
        if reminder.message.parentMessageId != nil {
            channelNameLabel.text = "Thread in # \(channelName)"
        } else {
            channelNameLabel.text = "# \(channelName)"
        }

        if reminder.message.text.isEmpty {
            let attachmentType = reminder.message.allAttachments.first?.type.rawValue.capitalized ?? ""
            messageLabel.text = "📎 \(attachmentType)"
        } else {
            messageLabel.text = reminder.message.text
        }
        
        // Configure based on reminder type
        if let remindAt = reminder.remindAt {
            // Check if reminder is overdue
            let now = Date()
            if remindAt < now {
                let timeInterval = now.timeIntervalSince(remindAt)
                dueDateLabel.text = formatOverdueTime(timeInterval: timeInterval)
                dueDateContainer.backgroundColor = Appearance.default.colorPalette.alert
            } else {
                let timeInterval = remindAt.timeIntervalSince(now)
                dueDateLabel.text = "Due in \(formatDueTime(timeInterval: timeInterval))"
                dueDateContainer.backgroundColor = Appearance.default.colorPalette.accentPrimary
            }
            dueDateContainer.isHidden = false
            saveForLaterIconView.isHidden = true
        } else {
            saveForLaterIconView.isHidden = false
            dueDateContainer.isHidden = true
        }
    }
    
    private func formatOverdueTime(timeInterval: TimeInterval) -> String {
        // Round to the nearest minute (30 seconds or more rounds up)
        let roundedMinutes = ceil(timeInterval / 60 - 0.5)
        let roundedInterval = roundedMinutes * 60
        
        // If less than a minute, show "1 min" instead of "0 min"
        if roundedInterval == 0 {
            return "Overdue by 1 min"
        }
        
        let formatter = DateComponentsFormatter()
        
        if roundedInterval < 3600 {
            // For durations less than an hour, show only minutes
            formatter.allowedUnits = [.minute]
            formatter.unitsStyle = .abbreviated
            formatter.maximumUnitCount = 1
        } else {
            // For longer durations, show days and hours, or hours and minutes
            formatter.allowedUnits = [.day, .hour, .minute]
            formatter.unitsStyle = .abbreviated
            formatter.maximumUnitCount = 2
        }
        
        guard let formattedString = formatter.string(from: roundedInterval) else {
            return "Overdue"
        }
        
        return "Overdue by \(formattedString)"
    }
    
    private func formatDueTime(timeInterval: TimeInterval) -> String {
        // Round to the nearest minute (30 seconds or more rounds up)
        let roundedMinutes = ceil(timeInterval / 60 - 0.5)
        let roundedInterval = roundedMinutes * 60
        
        // If less than a minute, show "1 min" instead of "0 min"
        if roundedInterval == 0 {
            return "1m"
        }
        
        let formatter = DateComponentsFormatter()
        
        if roundedInterval < 3600 {
            // For durations less than an hour, show only minutes
            formatter.allowedUnits = [.minute]
            formatter.unitsStyle = .abbreviated
            formatter.maximumUnitCount = 1
        } else {
            // For longer durations, show days and hours, or hours and minutes
            formatter.allowedUnits = [.day, .hour, .minute]
            formatter.unitsStyle = .abbreviated
            formatter.maximumUnitCount = 2
        }
        
        guard let formattedString = formatter.string(from: roundedInterval) else {
            return "soon"
        }
        
        return formattedString
    }
}
