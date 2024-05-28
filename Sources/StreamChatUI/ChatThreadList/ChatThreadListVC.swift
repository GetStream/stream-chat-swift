//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

// TODO: Make sure the ThreadListQuery used is efficient and only the necessary data is fetched.

/// A `UIViewController` subclass  that shows the list of threads which the current user is participating.
@available(iOSApplicationExtension, unavailable)
open class ChatThreadListVC:
    _ViewController,
    ThemeProvider,
    ChatThreadListControllerDelegate,
    UITableViewDelegate,
    UITableViewDataSource
{
    /// The `ChatThreadListController` instance that provides the threads data.
    public var threadListController: ChatThreadListController

    public init(threadListController: ChatThreadListController) {
        self.threadListController = threadListController
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// The current thread list data.
    public private(set) var threads: [ChatThread] = []

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

    override open func setUp() {
        super.setUp()

        threadListController.delegate = self
        threadListController.synchronize()

        tableView.delegate = self
        tableView.dataSource = self

        viewPaginationHandler.bottomThreshold = 800
        viewPaginationHandler.onNewBottomPage = { [weak self] in
            self?.loadMoreThreads()
        }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        
        tableView.backgroundColor = appearance.colorPalette.background
    }

    override open func setUpLayout() {
        super.setUpLayout()
        
        view.embed(tableView)
    }

    // MARK: - Actions

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

    /// Called when loading a new page of threads is finished.
    open func didFinishLoadingMoreThreads(with result: Result<[ChatThread], Error>) {
        isPaginatingThreads = false
    }

    // MARK: - ChatThreadListControllerDelegate

    open func controller(_ controller: ChatThreadListController, didChangeThreads changes: [ListChange<ChatThread>]) {
        threads = Array(controller.threads)
        tableView.reloadData()
    }

    open func controller(_ controller: DataController, didChangeState state: DataController.State) {
        // TODO:
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        threads.count
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let thread = threads[indexPath.row]
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "thread-cell")
        cell.textLabel?.text = thread.parentMessageId
        cell.detailTextLabel?.text = "\(thread.reads.first(where: { $0.user.id == threadListController.client.currentUserId })?.unreadMessagesCount ?? 0)"
        return cell
    }

    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let thread = threads[indexPath.row]
        let client = threadListController.client
        let threadVC = components.threadVC.init()
        threadVC.channelController = client.channelController(for: thread.channel.cid)
        threadVC.messageController = client.messageController(
            cid: thread.channel.cid,
            messageId: thread.parentMessageId
        )
        navigationController?.show(threadVC, sender: self)
    }
}
