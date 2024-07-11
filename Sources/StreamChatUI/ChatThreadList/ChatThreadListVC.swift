//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view controller used to display the list of threads the current user is participating.
@available(iOSApplicationExtension, unavailable)
open class ChatThreadListVC:
    _ViewController,
    ThemeProvider,
    ChatThreadListControllerDelegate,
    EventsControllerDelegate,
    UITableViewDelegate,
    UITableViewDataSource
{
    /// The `ChatThreadListController` instance that provides the threads data.
    public var threadListController: ChatThreadListController

    /// The `EventsController` instance that observes thread events.
    public var eventsController: EventsController

    public init(
        threadListController: ChatThreadListController,
        eventsController: EventsController
    ) {
        self.threadListController = threadListController
        self.eventsController = eventsController
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// The current thread list data.
    public private(set) var threads: [ChatThread] = []

    /// The number of new threads available to be fetched.
    public var newAvailableThreadIds: Set<MessageId> = [] {
        didSet {
            updateHeaderBannerViewContent()
        }
    }

    /// A boolean value that controls whether it is loading more threads at the moment or not.
    private var isPaginatingThreads = false

    /// A component responsible to handle when to load new channels.
    private lazy var viewPaginationHandler: ViewPaginationHandling = {
        ScrollViewPaginationHandler(scrollView: tableView)
    }()

    /// The `UITableView` instance that displays the thread list.
    open private(set) lazy var tableView: UITableView = UITableView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "tableView")

    /// The loading indicator shown at the top when fetching new threads.
    open private(set) lazy var loadingBannerIndicator: UIActivityIndicatorView = {
        UIActivityIndicatorView(style: .medium)
    }()

    /// The banner view shown by default as a table view header to fetch unread threads.
    open private(set) lazy var headerBannerView: ChatThreadListHeaderBannerView = components
        .threadListHeaderBannerView.init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "headerBannerView")

    /// The thread list error view that is shown when loading threads fails.
    open private(set) lazy var errorView: ChatThreadListErrorView = components
        .threadListErrorView.init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "errorView")

    /// The thread list loading view.
    open private(set) lazy var loadingView: ChatThreadListLoadingView = components
        .threadListLoadingView.init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "loadingView")

    /// The empty view when there are no threads.
    open private(set) lazy var emptyView: ChatThreadListEmptyView = components
        .threadListEmptyView.init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "emptyView")

    /// A router object responsible for handling navigation actions of this view controller.
    open lazy var router: ChatThreadListRouter = components
        .threadListRouter
        .init(rootViewController: self)

    override open func setUp() {
        super.setUp()

        threadListController.synchronize { [weak self] error in
            self?.didFinishSynchronizingThreads(with: error)
        }
        threadListController.delegate = self
        eventsController.delegate = self

        tableView.register(ChatThreadListItemCell.self)
        tableView.delegate = self
        tableView.dataSource = self

        headerBannerView.onAction = { [weak self] in
            self?.didTapOnHeaderBannerView()
        }

        errorView.onAction = { [weak self] in
            self?.didTapOnErrorView()
        }

        viewPaginationHandler.bottomThreshold = 800
        viewPaginationHandler.onNewBottomPage = { [weak self] in
            self?.loadMoreThreads()
        }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        tableView.backgroundColor = appearance.colorPalette.background
        tableView.separatorStyle = .singleLine
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.embed(tableView)
        view.embed(loadingView)
        view.embed(emptyView)

        view.addSubview(errorView)
        errorView.pin(anchors: [.leading, .trailing], to: view)
        errorView.bottomAnchor.pin(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true

        hideLoadingView()
        hideEmptyView()
        hideErrorView()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !newAvailableThreadIds.isEmpty {
            showLoadingBannerView()
            threadListController.synchronize { [weak self] error in
                self?.didFinishSynchronizingThreads(with: error)
            }
        }
    }

    /// Loads the next page of threads. This action is triggered when reaching the bottom of the list view.
    open func loadMoreThreads() {
        guard !isPaginatingThreads && !threadListController.hasLoadedAllThreads else {
            return
        }

        isPaginatingThreads = true
        threadListController.loadMoreThreads { [weak self] result in
            self?.didFinishLoadingMoreThreads(with: result)
        }
    }

    /// The user tapped on the banner view to load new threads.
    open func didTapOnHeaderBannerView() {
        hideHeaderBannerView()
        showLoadingBannerView()
        threadListController.synchronize { [weak self] error in
            self?.didFinishSynchronizingThreads(with: error)
        }
    }

    /// The user tapped on the error view to refresh the data.
    open func didTapOnErrorView() {
        hideErrorView()

        /// If the view already contains data, do not show the loading spinner
        /// above it, but show the loading banner instead.
        if threads.isEmpty {
            showLoadingView()
        } else {
            hideHeaderBannerView()
            showLoadingBannerView()
        }

        threadListController.synchronize { [weak self] error in
            self?.didFinishSynchronizingThreads(with: error)
        }
    }

    // Called when the syncing of the `threadListController` is finished.
    /// - Parameter error: An `error` if the syncing failed; `nil` if it was successful.
    open func didFinishSynchronizingThreads(with error: Error?) {
        hideLoadingView()
        hideLoadingBannerView()
        newAvailableThreadIds = []
    }

    /// Called when loading a new page of threads is finished.
    open func didFinishLoadingMoreThreads(with result: Result<[ChatThread], Error>) {
        isPaginatingThreads = false
    }

    /// Updates the threads header banner view content.
    open func updateHeaderBannerViewContent() {
        headerBannerView.content = .init(newThreadsCount: newAvailableThreadIds.count)
    }

    // MARK: - Show/Hide state views

    /// Displays the header banner view when there are thread updates to be fetched.
    open func showHeaderBannerView() {
        tableView.tableHeaderView = headerBannerView
        headerBannerView.widthAnchor.pin(equalTo: tableView.widthAnchor).isActive = true
        headerBannerView.layoutIfNeeded()
    }

    /// Hides the header banner view.
    open func hideHeaderBannerView() {
        Animate {
            self.tableView.tableHeaderView = nil
            self.tableView.layoutIfNeeded()
        }
    }

    /// Shows the loading banner view when fetching unread threads.
    open func showLoadingBannerView() {
        loadingBannerIndicator.startAnimating()
        tableView.tableHeaderView = loadingBannerIndicator
    }

    /// Hides the loading banner view.
    open func hideLoadingBannerView() {
        Animate {
            self.tableView.tableHeaderView = nil
            self.tableView.layoutIfNeeded()
        }
    }

    /// Shows the loading view.
    open func showLoadingView() {
        loadingView.isHidden = false
    }
    
    /// Hides the loading view.
    open func hideLoadingView() {
        loadingView.isHidden = true
    }
    
    /// Shows the empty view.
    open func showEmptyView() {
        emptyView.isHidden = false
    }
    
    /// Hides the empty view.
    open func hideEmptyView() {
        emptyView.isHidden = true
    }
    
    /// Shows the error view.
    open func showErrorView() {
        errorView.isHidden = false
    }
    
    /// Hides the error view.
    open func hideErrorView() {
        errorView.isHidden = true
    }

    // MARK: - ChatThreadListControllerDelegate

    public func controller(_ controller: DataController, didChangeState state: DataController.State) {
        handleStateChanges(state)
    }

    open func controller(
        _ controller: ChatThreadListController,
        didChangeThreads changes: [ListChange<ChatThread>]
    ) {
        handleStateChanges(controller.state)
        
        let previousThreads = threads
        let newThreads = Array(controller.threads)
        let stagedChangeset = StagedChangeset(source: previousThreads, target: newThreads)
        tableView.reload(
            using: stagedChangeset,
            with: .fade,
            reconfigure: { _ in true }
        ) { [weak self] newThreads in
            self?.threads = newThreads
        }
    }

    /// Called whenever the threads data changes or the controller.state changes.
    open func handleStateChanges(_ newState: DataController.State) {
        switch newState {
        case .initialized, .localDataFetched:
            if threadListController.threads.isEmpty {
                showLoadingView()
            } else {
                hideLoadingView()
            }
        case .remoteDataFetched:
            hideLoadingView()
            hideErrorView()
            if threadListController.threads.isEmpty {
                showEmptyView()
            } else {
                hideEmptyView()
            }
        case .remoteDataFetchFailed:
            hideLoadingView()
            hideEmptyView()
            showErrorView()
        case .localDataFetchFailed:
            break
        }
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        threads.count
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let thread = threads[indexPath.row]
        let cell = tableView.dequeueReusableCell(with: ChatThreadListItemCell.self, for: indexPath)
        cell.components = components
        cell.itemView.content = .init(
            thread: thread,
            currentUserId: threadListController.client.currentUserId
        )
        return cell
    }

    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let thread = threads[indexPath.row]
        router.showThread(thread)
    }

    // MARK: - EventsControllerDelegate

    open func eventsController(_ controller: EventsController, didReceiveEvent event: any Event) {
        switch event {
        case let event as ThreadMessageNewEvent:
            guard let parentId = event.message.parentMessageId else { break }
            let isNewThread = threadListController.dataStore.thread(parentMessageId: parentId) == nil
            if isNewThread {
                newAvailableThreadIds.insert(parentId)
                if isViewVisible {
                    showHeaderBannerView()
                }
            }
        default:
            break
        }
    }
}

extension ChatThread: Differentiable, Equatable, Hashable {
    public static func == (lhs: ChatThread, rhs: ChatThread) -> Bool {
        lhs.parentMessageId == rhs.parentMessageId &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.parentMessage.isContentEqual(to: rhs.parentMessage) &&
            lhs.title == rhs.title &&
            lhs.reads == rhs.reads &&
            lhs.latestReplies == rhs.latestReplies &&
            lhs.lastMessageAt == rhs.lastMessageAt &&
            lhs.channel == rhs.channel &&
            lhs.participantCount == rhs.participantCount &&
            lhs.replyCount == rhs.replyCount &&
            lhs.threadParticipants == rhs.threadParticipants &&
            lhs.extraData == rhs.extraData
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(parentMessageId)
    }

    public var differenceIdentifier: Int {
        hashValue
    }

    public func isContentEqual(to source: ChatThread) -> Bool {
        self == source
    }
}
