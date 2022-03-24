//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

extension ChatClient {
    /// Creates a new `ChannelListController` with the provided channel query.
    /// - Parameter query: The query specify the filter and sorting of the channels the controller should fetch.    ///
    /// - Returns: A new instance of `ChatChannelListController`.
    public func channelListController(query: ChannelListQuery) -> ChatChannelListController {
        .init(query: query, client: self)
    }

    /// Creates a new `ChannelListController` with the provided channel query and filter block.
    /// - Parameters:
    ///   - query: The query specify the filter and sorting of the channels the controller should fetch.
    ///   - filterBlock: A block that determines whether the channels belongs to this controller.
    /// - Returns: A new instance of `ChatChannelListController`
    public func channelListController(
        query: ChannelListQuery,
        filterBlock: ((ChatChannel) -> Bool)? = nil
    ) -> ChatChannelListController {
        .init(query: query, client: self, filterBlock: filterBlock)
    }
}

/// `ChatChannelListController` is a controller class which allows observing a list of chat channels based on the provided query.
public class ChatChannelListController: DataController, DelegateCallable, DataStoreProvider {
    /// The query specifying and filtering the list of channels.
    public let query: ChannelListQuery
    
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient
    
    /// The channels matching the query of this controller.
    ///
    /// To observe changes of the channels, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    ///
    public var channels: LazyCachedMapCollection<ChatChannel> {
        startChannelListObserverIfNeeded()
        return channelListObserver.items
    }
    
    /// The worker used to fetch the remote data and communicate with servers.
    private lazy var worker: ChannelListUpdater = self.environment
        .channelQueryUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )

    /// A Boolean value that returns wether pagination is finished
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
    
    /// Used for observing the database for changes.
    private(set) lazy var channelListObserver: ListDatabaseObserver<ChatChannel, ChannelDTO> = {
        let request = ChannelDTO.channelListFetchRequest(query: self.query)
        let observer = self.environment.createChannelListDatabaseObserver(
            client.databaseContainer.viewContext,
            request,
            { $0.asModel() }
        )
        
        observer.onChange = { [weak self] changes in
            self?.delegateCallback { [weak self] in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }
                $0.controller(self, didChangeChannels: changes)
            }
            self?.handleLinkedChannels(changes)
        }

        observer.onWillChange = { [weak self] in
            self?.delegateCallback { [weak self] in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }

                $0.controllerWillChangeChannels(self)
            }
        }

        return observer
    }()
    
    lazy var updatedChannelObserver: ListDatabaseObserver<ChatChannel, ChannelDTO> = {
        let observer = self.environment.createChannelListDatabaseObserver(
            client.databaseContainer.viewContext,
            ChannelDTO.channelsFetchRequest(notLinkedTo: query),
            { $0.asModel() }
        )
        
        observer.onChange = { [weak self] changes in
            self?.handleUnlinkedChannels(changes)
        }
        
        return observer
    }()

    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    @available(iOS 13, *)
    lazy var basePublishers: BasePublishers = .init(controller: self)
    
    private let filterBlock: ((ChatChannel) -> Bool)?
    private let environment: Environment
    
    /// Creates a new `ChannelListController`.
    ///
    /// - Parameters:
    ///   - query: The query used for filtering the channels.
    ///   - client: The `Client` instance this controller belongs to.
    ///   - filterBlock: A block that determines whether the channels belongs to this controller.
    init(
        query: ChannelListQuery,
        client: ChatClient,
        filterBlock: ((ChatChannel) -> Bool)? = nil,
        environment: Environment = .init()
    ) {
        self.client = client
        self.query = query
        self.filterBlock = filterBlock
        self.environment = environment
        super.init()
        client.trackChannelListController(self)
    }
    
    override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
        startChannelListObserverIfNeeded()
        updateChannelList(completion)
    }
    
    private func updateChannelList(
        _ completion: ((_ error: Error?) -> Void)? = nil
    ) {
        worker.update(
            channelListQuery: query
        ) { result in
            switch result {
            case .success:
                self.state = .remoteDataFetched
                self.callback { completion?(nil) }
            case let .failure(error):
                self.state = .remoteDataFetchFailed(ClientError(with: error))
                self.callback { completion?(error) }
            }
        }
    }
    
    /// If the `state` of the controller is `initialized`, this method calls `startObserving` on the
    /// `channelListObserver` to fetch the local data and start observing the changes. It also changes
    /// `state` based on the result.
    ///
    /// It's safe to call this method repeatedly.
    ///
    private func startChannelListObserverIfNeeded() {
        guard state == .initialized else { return }
        do {
            try channelListObserver.startObserving()
            try updatedChannelObserver.startObserving()
            state = .localDataFetched
        } catch {
            state = .localDataFetchFailed(ClientError(with: error))
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
        }
    }

    private func channelBelongsToController(_ channel: ChatChannel) -> Bool {
        if let filterBlock = filterBlock {
            return filterBlock(channel)
        }
        do {
            return try channel.meets(query.filter)
        } catch {
            log.error("Unable to resolve complex filter. Please pass a `filterBlock` when intializing ChatChannelListController")
        }
        return true
    }
    
    private func handleUnlinkedChannels(_ changes: [ListChange<ChatChannel>]) {
        guard state == .remoteDataFetched else {
            log.debug("Ignoring inserted/updated unlinked channels due to query \(query) not being synced.")
            return
        }

        let channels = changes.compactMap { change -> ChatChannel? in
            switch change {
            case let .insert(channel, _):
                guard channelBelongsToController(channel) else { return nil }
                return (delegate?.controller(self, shouldAddNewChannelToList: channel) ?? true) ? channel : nil
            case let .update(channel, _):
                guard channelBelongsToController(channel) else { return nil }
                return (delegate?.controller(self, shouldListUpdatedChannel: channel) ?? true) ? channel : nil
            default: return nil
            }
        }
        link(channels: channels)
    }
    
    private func handleLinkedChannels(_ changes: [ListChange<ChatChannel>]) {
        let channels = changes.compactMap { change -> ChatChannel? in
            switch change {
            case let .update(channel, _):
                // We unlink the channels that do not belong to this controller
                guard channelBelongsToController(channel) else { return channel }
                return (delegate?.controller(self, shouldListUpdatedChannel: channel) ?? true) ? nil : channel
            default: return nil
            }
        }
        unlink(channels: channels)
    }
    
    private func link(channels: [ChatChannel]) {
        guard !channels.isEmpty else { return }
        client.databaseContainer.write { session in
            guard let queryDTO = session.channelListQuery(filterHash: self.query.filter.filterHash) else {
                log.debug("Channel list query has not yet created \(self.query)")
                return
            }
            
            for channel in channels {
                guard let channelDTO = session.channel(cid: channel.cid) else {
                    log.error("Channel \(channel.cid) cannot be found in database.")
                    continue
                }
                queryDTO.channels.insert(channelDTO)
            }
        }
    }
    
    private func unlink(channels: [ChatChannel]) {
        guard !channels.isEmpty else { return }
        client.databaseContainer.write { session in
            guard let queryDTO = session.channelListQuery(filterHash: self.query.filter.filterHash) else {
                log.debug("Channel list query has not yet created \(self.query)")
                return
            }
            
            for channel in channels {
                guard let channelDTO = session.channel(cid: channel.cid) else {
                    log.error("Channel \(channel.cid) cannot be found in database.")
                    continue
                }
                queryDTO.channels.remove(channelDTO)
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
        completion: ((Error?) -> Void)? = nil
    ) {
        if hasLoadedAllPreviousChannels {
            completion?(nil)
            return
        }

        let limit = limit ?? query.pagination.pageSize
        var updatedQuery = query
        updatedQuery.pagination = Pagination(pageSize: limit, offset: channels.count)
        worker.update(channelListQuery: updatedQuery) { result in
            switch result {
            case let .success(channels):
                self.hasLoadedAllPreviousChannels = channels.count < limit
                self.callback { completion?(nil) }
            case let .failure(error):
                self.callback { completion?(error) }
            }
        }
    }

    /// Marks all channels for a user as read.
    ///
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    public func markAllRead(completion: ((Error?) -> Void)? = nil) {
        worker.markAllRead { error in
            self.callback {
                completion?(error)
            }
        }
    }
}

extension ChatChannelListController {
    struct Environment {
        var channelQueryUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelListUpdater = ChannelListUpdater.init

        var createChannelListDatabaseObserver: (
            _ context: NSManagedObjectContext,
            _ fetchRequest: NSFetchRequest<ChannelDTO>,
            _ itemCreator: @escaping (ChannelDTO) -> ChatChannel
        )
            -> ListDatabaseObserver<ChatChannel, ChannelDTO> = {
                ListDatabaseObserver(context: $0, fetchRequest: $1, itemCreator: $2)
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
    /// The controller will update the list of observed channels.
    ///
    /// - Parameter controller: The controller emitting the change callback.
    ///
    func controllerWillChangeChannels(_ controller: ChatChannelListController)

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
    
    /// **This method is deprecated:** "Please use `filterBlock` when initializing a `ChatChannelListController`"
    /// (We are not using @available annotations because they do not get emitted in protocol conformances)
    ///
    /// The controller asks the delegate if the newly inserted `ChatChannel` should be linked to this Controller's query.
    /// Defaults to `true`
    /// - Parameters:
    ///   - controller: The controller,
    ///   - shouldAddNewChannelToList: The newly inserted `ChatChannel` instance. This instance is not linked to the controller's query.
    /// - Returns:
    ///     `true` if channel should be added to the list of observed channels, `false` if channel doesn't exists in this list.
    func controller(
        _ controller: ChatChannelListController,
        shouldAddNewChannelToList channel: ChatChannel
    ) -> Bool

    /// **This method is deprecated:** "Please use `filterBlock` when initializing a `ChatChannelListController`"
    /// (We are not using @available annotations because they do not get emitted in protocol conformances)
    ///
    /// The controller asks the delegate if the newly updated `ChatChannel` should be linked to this Controller's query.
    /// Defaults to `true`
    /// - Parameters:
    ///   - controller: The controller,
    ///   - shouldListUpdatedChannel: The newly updated `ChatChannel` instance.
    /// - Returns:
    ///     `true` if channel should be added to the list of observed channels, `false` if channel doesn't exists in this list.
    func controller(
        _ controller: ChatChannelListController,
        shouldListUpdatedChannel channel: ChatChannel
    ) -> Bool
}

public extension ChatChannelListControllerDelegate {
    func controllerWillChangeChannels(_ controller: ChatChannelListController) {}

    func controller(
        _ controller: ChatChannelListController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    ) {}
}

extension ClientError {
    public class FetchFailed: Error {
        public var localizedDescription: String = "Failed to perform fetch request. This is an internal error."
    }
}
