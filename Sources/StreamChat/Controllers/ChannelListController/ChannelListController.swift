//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension ChatClient {
    /// Creates a new `ChannelListController` with the provided channel query.
    /// - Parameter query: The query specify the filter and sorting of the channels the controller should fetch.    ///
    /// - Returns: A new instance of `ChatChannelListController`.
    public func channelListController(query: ChannelListQuery) -> ChatChannelListController {
        .init(query: query, client: self)
    }

    /// Creates a new `ChannelListController` with the provided channel query and filter block.
    ///
    /// When passing `filter`, make sure the runtime logic matches the one expected by the filter passed in the query object.
    /// If they don't match, there can be jumps when loading the list.
    ///
    /// - Parameters:
    ///   - query: The query specify the filter and sorting of the channels the controller should fetch.
    ///   - filter: A block that determines whether the channels belongs to this controller.
    /// - Returns: A new instance of `ChatChannelListController`
    public func channelListController(
        query: ChannelListQuery,
        filter: (@Sendable (ChatChannel) -> Bool)? = nil
    ) -> ChatChannelListController {
        .init(query: query, client: self, filter: filter)
    }
}

/// `ChatChannelListController` is a controller class which allows observing a list of chat channels based on the provided query.
///
/// - Note: For an async-await alternative of the `ChatChannelListController`, please check ``ChannelList`` in the async-await supported [state layer](https://getstream.io/chat/docs/sdk/ios/client/state-layer/state-layer-overview/).
public class ChatChannelListController: DataController, DelegateCallable, DataStoreProvider, @unchecked Sendable {
    /// The query specifying and filtering the list of channels.
    public internal(set) var query: ChannelListQuery

    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    /// The channels matching the query of this controller.
    ///
    /// To observe changes of the channels, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    ///
    public var channels: [ChatChannel] {
        startChannelListObserverIfNeeded()
        if Thread.current.isMainThread {
            return MainActor.assumeIsolated { channelList.state.channels }
        }
        return channelList.observer.items
    }

    /// A Boolean value that returns whether pagination is finished
    public private(set) var hasLoadedAllPreviousChannels: Bool = false

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<ChatChannelListControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)

            // After setting delegate local changes will be fetched and observed.
            startChannelListObserverIfNeeded()
        }
    }

    private let channelList: ChannelList
    let channelsChangesSubject = PassthroughSubject<[ListChange<ChatChannel>], Never>()

    /// Creates a new `ChannelListController`.
    ///
    /// - Parameters:
    ///   - query: The query used for filtering the channels.
    ///   - client: The `Client` instance this controller belongs to.
    ///   - filter: A block that determines whether the channels belongs to this controller.
    init(
        query: ChannelListQuery,
        client: ChatClient,
        filter: (@Sendable (ChatChannel) -> Bool)? = nil,
        environment: Environment = .init()
    ) {
        self.client = client
        self.query = query
        channelList = environment.channelListBuilder(query, filter, client)
        super.init()
    }

    override public func synchronize(_ completion: (@MainActor (_ error: Error?) -> Void)? = nil) {
        startChannelListObserverIfNeeded()
        Task { @MainActor in
            let pageSize = channelList.state.query.pagination.pageSize
            do {
                let channels = try await channelList.get()
                state = .remoteDataFetched
                query = channelList.state.query
                hasLoadedAllPreviousChannels = channels.count < pageSize
                completion?(nil)
            } catch {
                state = .remoteDataFetchFailed(ClientError(with: error))
                completion?(error)
            }
        }
    }

    // MARK: - Actions

    /// Loads next channels from backend.
    ///
    /// - Parameters:
    ///   - limit: Limit for page size.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    public func loadNextChannels(
        limit: Int? = nil,
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        startChannelListObserverIfNeeded()
        withOnMainCompletion {
            try await self.channelList.loadMoreChannels(limit: limit)
        } completion: { result in
            self.hasLoadedAllPreviousChannels = self.channelList.state.hasLoadedAllPreviousChannels
            completion?(result.error)
        }
    }

    // MARK: - Helpers

    func startChannelListObserverIfNeeded() {
        guard state == .initialized else { return }
        StreamConcurrency.onMain {
            state = .localDataFetched
            channelList.state.channelsDidChangeHandler = { [weak self] changes in
                guard let self else { return }
                channelsChangesSubject.send(changes)
                delegateCallback {
                    log.debug("didChangeChannels: \(changes.map(\.debugDescription))")
                    $0.controller(self, didChangeChannels: changes)
                }
            }
        }
    }
}

extension ChatChannelListController {
    struct Environment {
        var channelListBuilder: (
            _ query: ChannelListQuery,
            _ filter: (@Sendable (ChatChannel) -> Bool)?,
            _ client: ChatClient
        ) -> ChannelList = { query, filter, client in
            ChannelList(query: query, dynamicFilter: filter, client: client)
        }
    }
}

extension ChatChannelListController {
    /// Set the delegate of `ChannelListController` to observe the changes in the system.
    public weak var delegate: ChatChannelListControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }
}

/// `ChatChannelListController` uses this protocol to communicate changes to its delegate.
public protocol ChatChannelListControllerDelegate: DataControllerStateDelegate {
    /// The controller changed the list of observed channels.
    ///
    /// - Parameters:
    ///   - controller: The controller emitting the change callback.
    ///   - changes: The change to the list of channels.\
    ///
    func controller(
        _ controller: ChatChannelListController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    )
}

public extension ChatChannelListControllerDelegate {
    func controller(
        _ controller: ChatChannelListController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    ) {}
}

extension ClientError {
    public final class FetchFailed: Error {
        public let localizedDescription: String = "Failed to perform fetch request. This is an internal error."
    }
}
