//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat
import UIKit

/// The ViewModel for the `ChatThreadListView`.
open class ChatThreadListViewModel: ObservableObject, ChatThreadListControllerDelegate, EventsControllerDelegate {
    /// Context provided dependencies.
    public var chatClient: ChatClient!

    /// The controller that manages the thread list data.
    private var threadListController: ChatThreadListController!

    /// The controller that manages thread list events.
    private var eventsController: EventsController!

    /// A boolean value indicating if the initial threads have been loaded.
    public private(set) var hasLoadedThreads = false

    /// The current selected thread.
    @Published public var selectedThread: ThreadSelectionInfo?

    /// The list of threads.
    @Published public var threads = LazyCachedMapCollection<ChatThread>()

    /// A boolean indicating if it is loading data from the server and no local cache is available.
    @Published public var isLoading = false

    /// A boolean indicating if it is reloading data from the server.
    @Published public var isReloading = false

    /// A boolean indicating that there is no data from server.
    @Published public var isEmpty = false

    /// A boolean indicating if it failed loading the initial data from the server.
    @Published public var failedToLoadThreads = false

    /// A boolean indicating if it failed loading threads while paginating.
    @Published public var failedToLoadMoreThreads = false

    /// A boolean value indicating if the view is currently loading more threads.
    @Published public var isLoadingMoreThreads: Bool = false

    /// A boolean value indicating if all the older threads are loaded.
    @Published public var hasLoadedAllThreads: Bool = false

    /// The number of new threads available to be fetched.
    @Published public var newThreadsCount: Int = 0

    /// A boolean value indicating if there are new threads available to be fetched.
    @Published public var hasNewThreads: Bool = false

    /// The ids of the new threads available to be fetched.
    private var newAvailableThreadIds: Set<MessageId> = [] {
        didSet {
            newThreadsCount = newAvailableThreadIds.count
            hasNewThreads = newThreadsCount > 0
        }
    }

    /// Creates a view model for the `ChatThreadListView`.
    ///
    /// - Parameters:
    ///   - threadListController: A controller providing the list of threads. If nil, a controller with default `ThreadListQuery` is created.
    ///   - eventsController: The controller that manages thread list events. If nil, the default events controller will be provided.
    public init(
        threadListController: ChatThreadListController? = nil,
        eventsController: EventsController? = nil
    ) {
        if let threadListController = threadListController {
            self.threadListController = threadListController
        } else {
            makeDefaultThreadListController()
        }

        if let eventsController = eventsController {
            self.eventsController = eventsController
        } else {
            makeDefaultEventsController()
        }
    }

    /// Re-fetches the threads. If the initial query failed, it will load the initial page.
    /// If on the other hand it was a new page that failed, it will re-fetch that page.
    public func retryLoadThreads() {
        if failedToLoadMoreThreads {
            loadMoreThreads()
            return
        }

        loadThreads()
    }

    /// Called when the view appears on screen.
    ///
    /// By default it will load the initial threads and start observing new data.
    public func viewDidAppear() {
        if !hasLoadedThreads {
            startObserving()
            loadThreads()
        }
    }

    /// Starts observing new data.
    public func startObserving() {
        threadListController.delegate = self
        eventsController?.delegate = self
    }

    /// Loads the initial page of threads.
    public func loadThreads() {
        let isEmpty = threadListController.threads.isEmpty
        isLoading = isEmpty
        failedToLoadThreads = false
        isReloading = !isEmpty
        preselectThreadIfNeeded()
        threadListController.synchronize { [weak self] error in
            self?.isLoading = false
            self?.isReloading = false
            self?.hasLoadedThreads = error == nil
            self?.failedToLoadThreads = error != nil
            self?.isEmpty = self?.threadListController.threads.isEmpty == true
            self?.preselectThreadIfNeeded()
            self?.hasLoadedAllThreads = self?.threadListController.hasLoadedAllThreads ?? false
            if error == nil {
                self?.newAvailableThreadIds = []
            }
        }
    }

    /// Called when a thread in the list is shown on screen.
    public func didAppearThread(at index: Int) {
        guard index >= threads.count - 5 else {
            return
        }

        loadMoreThreads()
    }

    /// Loads the next page of threads.
    public func loadMoreThreads() {
        if isLoadingMoreThreads || threadListController.hasLoadedAllThreads == true {
            return
        }

        isLoadingMoreThreads = true
        threadListController.loadMoreThreads { [weak self] result in
            self?.isLoadingMoreThreads = false
            self?.hasLoadedAllThreads = self?.threadListController.hasLoadedAllThreads ?? false
            let threads = try? result.get()
            self?.failedToLoadMoreThreads = threads == nil
        }
    }

    public func controller(
        _ controller: ChatThreadListController,
        didChangeThreads changes: [ListChange<ChatThread>]
    ) {
        threads = controller.threads
    }

    public func eventsController(_ controller: EventsController, didReceiveEvent event: any Event) {
        switch event {
        case let event as ThreadMessageNewEvent:
            guard let parentId = event.message.parentMessageId else { break }
            let isNewThread = threadListController.dataStore.thread(parentMessageId: parentId) == nil
            if isNewThread {
                newAvailableThreadIds.insert(parentId)
            }
        default:
            break
        }
    }

    private func makeDefaultThreadListController() {
        threadListController = chatClient.threadListController(
            query: .init(watch: true)
        )
        chatClient = threadListController.client
    }

    private func makeDefaultEventsController() {
        eventsController = chatClient.eventsController()
    }

    private func preselectThreadIfNeeded() {
        guard let firstThread = threads.first else { return }
        guard selectedThread == nil else { return }

        selectedThread = .init(thread: firstThread)
    }
}

public struct ThreadSelectionInfo: Identifiable {
    public let id: String
    public let thread: ChatThread

    public init(thread: ChatThread) {
        self.thread = thread
        id = thread.id
    }
}

extension ThreadSelectionInfo: Hashable, Equatable {
    public static func == (lhs: ThreadSelectionInfo, rhs: ThreadSelectionInfo) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension ChatThread: Identifiable {
    public var id: String {
        parentMessageId
    }
}
