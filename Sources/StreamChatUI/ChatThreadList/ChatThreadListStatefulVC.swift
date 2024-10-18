//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat
import UIKit

/// The view controller used to display the list of threads the current user is participating.
@available(iOSApplicationExtension, unavailable)
open class ChatThreadListStatefulVC:
    _ViewController,
    ThemeProvider,
    UITableViewDelegate,
    UITableViewDataSource
{
    var viewModel: ChatThreadListViewModel

    public init(
        viewModel: ChatThreadListViewModel
    ) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The current thread list data.
    public private(set) var threads: [ChatThread] = []

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
    open lazy var router: ChatThreadListStatefulRouter = ChatThreadListStatefulRouter(rootViewController: self)

    private var cancellables = Set<AnyCancellable>()

    override open func setUp() {
        super.setUp()

        tableView.register(ChatThreadListItemCell.self)
        tableView.delegate = self
        tableView.dataSource = self

        headerBannerView.onAction = { [weak self] in
            self?.viewModel.loadThreads()
        }
        errorView.onAction = { [weak self] in
            self?.viewModel.retryLoadThreads()
        }
        viewPaginationHandler.bottomThreshold = 800
        viewPaginationHandler.onNewBottomPage = { [weak self] in
            self?.viewModel.loadMoreThreads()
        }

        viewModel.$threads
            .sink { [weak self] threads in
                guard let self = self else { return }
                let previousThreads = self.threads
                let newThreads = Array(threads)
                let stagedChangeset = StagedChangeset(source: previousThreads, target: newThreads)
                tableView.reload(
                    using: stagedChangeset,
                    with: .fade,
                    reconfigure: { _ in true }
                ) { [weak self] newThreads in
                    self?.threads = newThreads
                }
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.showLoadingView()
                } else {
                    self?.hideLoadingView()
                }
            }
            .store(in: &cancellables)

        viewModel.$isEmpty
            .sink { [weak self] isEmpty in
                if isEmpty {
                    self?.showEmptyView()
                } else {
                    self?.hideEmptyView()
                }
            }
            .store(in: &cancellables)

        viewModel.$failedToLoadThreads
            .sink { [weak self] failed in
                if failed {
                    self?.showErrorView()
                } else {
                    self?.hideErrorView()
                }
            }
            .store(in: &cancellables)

        viewModel.$hasNewThreads
            .sink { [weak self] hasNewThreads in
                if hasNewThreads {
                    self?.showHeaderBannerView()
                } else {
                    self?.hideHeaderBannerView()
                }
            }
            .store(in: &cancellables)

        viewModel.$isReloading
            .sink { [weak self] isReloading in
                if isReloading {
                    self?.showLoadingBannerView()
                } else {
                    self?.hideLoadingBannerView()
                }
            }
            .store(in: &cancellables)

        viewModel.$newThreadsCount
            .sink { [weak self] newThreadsCount in
                self?.headerBannerView.content = .init(newThreadsCount: newThreadsCount)
            }
            .store(in: &cancellables)
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

        viewModel.viewDidAppear()
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
            currentUserId: viewModel.chatClient.currentUserId
        )
        return cell
    }

    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let thread = threads[indexPath.row]
        router.showThread(thread)
    }
}

extension Publisher where Failure == Never {
    /// Assigns each element from a publisher to a property on an object without retaining the object.
    func assignWeakly<Root: AnyObject>(
        to keyPath: ReferenceWritableKeyPath<Root, Output>,
        on root: Root
    ) -> AnyCancellable {
        sink { [weak root] in
            root?[keyPath: keyPath] = $0
        }
    }
}
