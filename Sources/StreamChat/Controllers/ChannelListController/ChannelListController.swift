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
    
    private var connectionObserver: EventObserver?
    private let requestedChannelsLimit = 25

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
            self?.delegateCallback { [weak self] in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }
                $0.controller(self, didChangeChannels: changes)
            }
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
        setupEventObserversIfNeeded(completion: completion)
    }
    
    private func setupEventObserversIfNeeded(completion: ((_ error: Error?) -> Void)? = nil) {
        guard !client.config.isLocalStorageEnabled else {
            return updateChannelList(trumpExistingChannels: false, completion)
        }
        
        updateChannelList(trumpExistingChannels: channels.count > requestedChannelsLimit) { [weak self] error in
            completion?(error)
            
            guard let self = self else { return }
            self.connectionObserver = nil
            // We can't setup event observers in connectionless mode
            guard let webSocketClient = self.client.webSocketClient else { return }
            let center = webSocketClient.eventNotificationCenter
            // We setup a `Connected` Event observer so every time we're connected,
            // we refresh the channel list
            self.connectionObserver = EventObserver(
                notificationCenter: center,
                transform: { $0 as? ConnectionStatusUpdated },
                callback: { [weak self] in
                    guard let self = self else {
                        log.warning("Callback called while self is nil")
                        return
                    }

                    switch $0.webSocketConnectionState {
                    case .connected:
                        self.updateChannelList(trumpExistingChannels: self.channels.count > self.requestedChannelsLimit)
                    default:
                        break
                    }
                }
            )
        }
    }
    
    private func updateChannelList(
        trumpExistingChannels: Bool,
        _ completion: ((_ error: Error?) -> Void)? = nil
    ) {
        worker.update(
            channelListQuery: query,
            trumpExistingChannels: trumpExistingChannels
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

        let limit = limit ?? requestedChannelsLimit
        var updatedQuery = query
        updatedQuery.pagination = Pagination(pageSize: limit, offset: channels.count)
        worker.update(channelListQuery: updatedQuery) { result in
            switch result {
            case let .success(payload):
                self.hasLoadedAllPreviousChannels = payload.channels.count < limit
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

// MARK: - Delegate type eraser

class AnyChannelListControllerDelegate: ChatChannelListControllerDelegate {
    private var _controllerWillChangeChannels: (ChatChannelListController) -> Void
    private var _controllerDidChangeChannels: (ChatChannelListController, [ListChange<ChatChannel>])
        -> Void
    private var _controllerDidChangeState: (DataController, DataController.State) -> Void
    
    weak var wrappedDelegate: AnyObject?
    
    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeState: @escaping (DataController, DataController.State) -> Void,
        controllerWillChangeChannels: @escaping (ChatChannelListController) -> Void,
        controllerDidChangeChannels: @escaping (ChatChannelListController, [ListChange<ChatChannel>])
            -> Void
    ) {
        self.wrappedDelegate = wrappedDelegate
        _controllerDidChangeState = controllerDidChangeState
        _controllerWillChangeChannels = controllerWillChangeChannels
        _controllerDidChangeChannels = controllerDidChangeChannels
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
}

extension AnyChannelListControllerDelegate {
    convenience init<Delegate: ChatChannelListControllerDelegate>(_ delegate: Delegate) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerWillChangeChannels: { [weak delegate] in delegate?.controllerWillChangeChannels($0) },
            controllerDidChangeChannels: { [weak delegate] in delegate?.controller($0, didChangeChannels: $1) }
        )
    }
}

extension AnyChannelListControllerDelegate {
    convenience init(_ delegate: ChatChannelListControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerWillChangeChannels: { [weak delegate] in delegate?.controllerWillChangeChannels($0) },
            controllerDidChangeChannels: { [weak delegate] in delegate?.controller($0, didChangeChannels: $1) }
        )
    }
}
