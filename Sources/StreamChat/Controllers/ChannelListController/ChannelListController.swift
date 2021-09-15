//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

extension ChatClient {
    /// Creates a new `ChannelListController` with the provided channel query.
    ///
    /// - Parameter query: The query specify the filter and sorting of the channels the controller should fetch.
    ///
    /// - Returns: A new instance of `ChannelController`.
    ///
    public func channelListController(query: ChannelListQuery) -> ChatChannelListController {
        .init(query: query, client: self)
    }
}

/// `_ChatChannelListController` is a controller class which allows observing a list of chat channels based on the provided query.
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
    var multicastDelegate: MulticastDelegate<AnyChannelListControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.mainDelegate = multicastDelegate.mainDelegate
            stateMulticastDelegate.additionalDelegates = multicastDelegate.additionalDelegates
            
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
            self?.delegateCallback {
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }
                
                for change in changes {
                    if case .remove = change {
                        self.hasLoadedAllPreviousChannels = false
                    }
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
    
    private let environment: Environment
    
    /// Creates a new `ChannelListController`.
    ///
    /// - Parameters:
    ///   - query: The query used for filtering the channels.
    ///   - client: The `Client` instance this controller belongs to.
    init(query: ChannelListQuery, client: ChatClient, environment: Environment = .init()) {
        self.client = client
        self.query = query
        self.environment = environment
    }
    
    override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
        startChannelListObserverIfNeeded()
        
        queryChannels(offset: 0) { error in
            if let error = error {
                self.state = .remoteDataFetchFailed(ClientError(with: error))
            } else {
                self.state = .remoteDataFetched
            }
            self.callback { completion?(error) }
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
    
    /// Sets the provided object as a delegate of this controller.
    ///
    /// - Parameter delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object
    /// alive if you want keep receiving updates.
    ///
    public func setDelegate<Delegate: ChatChannelListControllerDelegate>(_ delegate: Delegate) {
        multicastDelegate.mainDelegate = AnyChannelListControllerDelegate(delegate)
    }
    
    private func handleUnlinkedChannels(_ changes: [ListChange<ChatChannel>]) {
        let channels = changes.compactMap { change -> ChatChannel? in
            switch change {
            case let .insert(channel, _):
                return (delegate?.controller(self, shouldLinkNewChannel: channel) ?? false) ? channel : nil
            case let .update(channel, _):
                return (delegate?.controller(self, shouldLinkUpdatedChannel: channel) ?? false) ? channel : nil
            default: return nil
            }
        }
        link(channels: channels)
    }
    
    private func handleLinkedChannels(_ changes: [ListChange<ChatChannel>]) {
        let channels = changes.compactMap { change -> ChatChannel? in
            switch change {
            case let .update(channel, _):
                return (delegate?.controller(self, shouldUnlinkUpdatedChannel: channel) ?? false) ? channel : nil
            default: return nil
            }
        }
        unlink(channels: channels)
    }
    
    private func link(channels: [ChatChannel]) {
        guard !channels.isEmpty else { return }
        client.databaseContainer.write { session in
            for channel in channels {
                guard let channelDTO = session.channel(cid: channel.cid) else {
                    log.error("Channel \(channel.cid) cannot be found in database.")
                    continue
                }
                let query = session.saveQuery(query: self.query)
                query.channels.insert(channelDTO)
            }
        }
    }
    
    private func unlink(channels: [ChatChannel]) {
        guard !channels.isEmpty else { return }
        client.databaseContainer.write { session in
            for channel in channels {
                guard let channelDTO = session.channel(cid: channel.cid) else {
                    log.error("Channel \(channel.cid) cannot be found in database.")
                    continue
                }
                let query = session.saveQuery(query: self.query)
                query.channels.remove(channelDTO)
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
        queryChannels(limit: limit) { error in
            self.callback { completion?(error) }
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
    
    private func queryChannels(
        offset: Int? = nil,
        limit: Int? = nil,
        completion: @escaping (Error?) -> Void
    ) {
        guard !hasLoadedAllPreviousChannels else {
            completion(nil)
            return
        }
        
        var updatedQuery = query
        updatedQuery.pagination = Pagination(
            pageSize: limit ?? query.pagination.pageSize,
            offset: offset ?? channels.count
        )
        
        worker.update(channelListQuery: updatedQuery) {
            switch $0 {
            case let .success(payload):
                self.hasLoadedAllPreviousChannels = payload.channels.count < updatedQuery.pagination.pageSize
                completion(nil)
            case let .failure(error):
                completion(error)
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
        get { multicastDelegate.mainDelegate?.wrappedDelegate as? ChatChannelListControllerDelegate }
        set { multicastDelegate.mainDelegate = AnyChannelListControllerDelegate(newValue) }
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
    
    /// The controller asks the delegate if the newly inserted `ChatChannel` should be linked to this Controller's query.
    /// Defaults to `false`
    /// - Parameters:
    ///   - controller: The controller,
    ///   - shouldLinkNewChannel: The newly inserted `ChatChannel` instance. This instance is not linked to the controller's query.
    func controller(
        _ controller: ChatChannelListController,
        shouldLinkNewChannel channel: ChatChannel
    ) -> Bool
    
    /// The controller asks the delegate if the newly updated `ChatChannel` should be linked to this Controller's query.
    /// Defaults to `false`
    /// - Parameters:
    ///   - controller: The controller,
    ///   - shouldLinkUpdatedChannel: The newly updated `ChatChannel` instance. This instance is not linked to the controller's query.
    func controller(
        _ controller: ChatChannelListController,
        shouldLinkUpdatedChannel channel: ChatChannel
    ) -> Bool
    
    /// The controller asks the delegate if the newly updated `ChatChannel` should be unlinked from this Controller's query.
    /// Defaults to `false`
    /// - Parameters:
    ///   - controller: The controller,
    ///   - shouldUnlinkUpdatedChannel: The newly updated `ChatChannel` instance. This instance is linked to the controller's query.
    func controller(
        _ controller: ChatChannelListController,
        shouldUnlinkUpdatedChannel channel: ChatChannel
    ) -> Bool
}

public extension ChatChannelListControllerDelegate {
    func controllerWillChangeChannels(_ controller: ChatChannelListController) {}

    func controller(
        _ controller: ChatChannelListController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    ) {}
    
    func controller(
        _ controller: ChatChannelListController,
        shouldLinkNewChannel channel: ChatChannel
    ) -> Bool { false }
    
    func controller(
        _ controller: ChatChannelListController,
        shouldLinkUpdatedChannel channel: ChatChannel
    ) -> Bool { false }
    
    func controller(
        _ controller: ChatChannelListController,
        shouldUnlinkUpdatedChannel channel: ChatChannel
    ) -> Bool { false }
}

extension ClientError {
    public class FetchFailed: Error {
        public var localizedDescription: String = "Failed to perform fetch request. This is an internal error."
    }
}

// MARK: - Delegate type eraser

class AnyChannelListControllerDelegate: ChatChannelListControllerDelegate {
    private var _controllerWillChangeChannels: (ChatChannelListController) -> Void
    private var _controllerDidChangeChannels: (ChatChannelListController, [ListChange<ChatChannel>])
        -> Void
    private var _controllerDidChangeState: (DataController, DataController.State) -> Void
    private var _controllerShouldLinkNewChannel: (ChatChannelListController, ChatChannel) -> Bool
    private var _controllerShouldLinkUpdatedChannel: (ChatChannelListController, ChatChannel) -> Bool
    private var _controllerShouldUnlinkUpdatedChannel: (ChatChannelListController, ChatChannel) -> Bool
    
    weak var wrappedDelegate: AnyObject?
    
    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeState: @escaping (DataController, DataController.State) -> Void,
        controllerWillChangeChannels: @escaping (ChatChannelListController) -> Void,
        controllerDidChangeChannels: @escaping (ChatChannelListController, [ListChange<ChatChannel>])
            -> Void,
        controllerShouldLinkNewChannel: @escaping (ChatChannelListController, ChatChannel) -> Bool,
        controllerShouldLinkUpdatedChannel: @escaping (ChatChannelListController, ChatChannel) -> Bool,
        controllerShouldUnlinkUpdatedChannel: @escaping (ChatChannelListController, ChatChannel) -> Bool
    ) {
        self.wrappedDelegate = wrappedDelegate
        _controllerDidChangeState = controllerDidChangeState
        _controllerWillChangeChannels = controllerWillChangeChannels
        _controllerDidChangeChannels = controllerDidChangeChannels
        _controllerShouldLinkNewChannel = controllerShouldLinkNewChannel
        _controllerShouldLinkUpdatedChannel = controllerShouldLinkUpdatedChannel
        _controllerShouldUnlinkUpdatedChannel = controllerShouldUnlinkUpdatedChannel
    }

    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        _controllerDidChangeState(controller, state)
    }

    func controllerWillChangeChannels(_ controller: ChatChannelListController) {
        _controllerWillChangeChannels(controller)
    }

    func controller(
        _ controller: ChatChannelListController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    ) {
        _controllerDidChangeChannels(controller, changes)
    }
    
    func controller(_ controller: ChatChannelListController, shouldLinkNewChannel channel: ChatChannel) -> Bool {
        _controllerShouldLinkNewChannel(controller, channel)
    }
    
    func controller(_ controller: ChatChannelListController, shouldLinkUpdatedChannel channel: ChatChannel) -> Bool {
        _controllerShouldLinkUpdatedChannel(controller, channel)
    }
    
    func controller(_ controller: ChatChannelListController, shouldUnlinkUpdatedChannel channel: ChatChannel) -> Bool {
        _controllerShouldUnlinkUpdatedChannel(controller, channel)
    }
}

extension AnyChannelListControllerDelegate {
    convenience init(_ delegate: ChatChannelListControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerWillChangeChannels: { [weak delegate] in delegate?.controllerWillChangeChannels($0) },
            controllerDidChangeChannels: { [weak delegate] in delegate?.controller($0, didChangeChannels: $1) },
            controllerShouldLinkNewChannel: { [weak delegate] in delegate?.controller($0, shouldLinkNewChannel: $1) ?? false },
            controllerShouldLinkUpdatedChannel: { [weak delegate] in
                delegate?.controller($0, shouldLinkUpdatedChannel: $1) ?? false
            },
            controllerShouldUnlinkUpdatedChannel: { [weak delegate] in
                delegate?.controller($0, shouldUnlinkUpdatedChannel: $1) ?? false
            }
        )
    }
}
