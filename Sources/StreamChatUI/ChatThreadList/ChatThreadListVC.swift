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

    /// A router object responsible for handling navigation actions of this view controller.
    open lazy var router: ChatThreadListRouter = components
        .threadListRouter
        .init(rootViewController: self)

    override open func setUp() {
        super.setUp()

        threadListController.delegate = self
        threadListController.synchronize()

        tableView.register(ChatThreadListItemCell.self)
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
        let previousThreads = threads
        let newThreads = Array(controller.threads)
        let stagedChangeset = StagedChangeset(source: previousThreads, target: newThreads)
        tableView.reload(
            using: stagedChangeset,
            with: .none,
            reconfigure: { _ in true }
        ) { [weak self] newThreads in
            self?.threads = newThreads
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
}

extension ChatThread: Differentiable, Hashable {
    public static func == (lhs: ChatThread, rhs: ChatThread) -> Bool {
        lhs.parentMessageId == rhs.parentMessageId
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(parentMessageId)
    }

    public func isContentEqual(to source: ChatThread) -> Bool {
        parentMessageId == source.parentMessageId &&
            updatedAt == source.updatedAt &&
            parentMessage == source.parentMessage &&
            title == source.title &&
            reads == source.reads &&
            latestReplies == source.latestReplies &&
            lastMessageAt == source.lastMessageAt &&
            channel == source.channel &&
            participantCount == source.participantCount &&
            replyCount == source.replyCount &&
            threadParticipants == source.threadParticipants &&
            extraData == source.extraData
    }
}
