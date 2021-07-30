//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

extension ChatClient {
    /// Creates a new `_ChatChannelWatcherListController` with the provided query.
    /// - Parameter query: The query specifying the pagination options for watchers the controller should fetch.
    /// - Returns: A new instance of `ChatChannelMemberListController`.
    public func watcherListController(query: ChannelWatcherListQuery) -> _ChatChannelWatcherListController<ExtraData> {
        .init(query: query, client: self)
    }
}

/// `_ChatChannelWatcherListController` is a controller class which allows observing a list of
/// channel watchers based on the provided query.
///
/// Learn more about `_ChatChannelWatcherListController` and its usage in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#user-list).
///
/// - Note: `ChatChannelWatcherListController` is a typealias of `_ChatChannelWatcherListController` with default extra data.
/// If you're using custom extra data, create your own typealias of `_ChatChannelWatcherListController`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
public typealias ChatChannelWatcherListController = _ChatChannelWatcherListController<NoExtraData>

/// `_ChatChannelWatcherListController` is a controller class which allows observing
/// a list of chat watchers based on the provided query.
///
/// Learn more about `_ChatChannelWatcherListController` and its usage in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#user-list).
///
/// - Note: `_ChatChannelWatcherListController` type is not meant to be used directly. If you're using default extra data, use
/// `ChatChannelWatcherListController` typealias instead. If you're using custom extra data, create your own typealias
/// of `_ChatChannelWatcherListController`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
public class _ChatChannelWatcherListController<ExtraData: ExtraDataTypes>: DataController, DelegateCallable, DataStoreProvider {
    /// The query specifying sorting and filtering for the list of channel watchers.
    @Atomic public private(set) var query: ChannelWatcherListQuery
    
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient
    
    /// The channel watchers matching the query.
    /// To observe the watcher list changes, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    public var watchers: LazyCachedMapCollection<ChatUser> {
        startObservingIfNeeded()
        return watchersObserver.items
    }
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    @available(iOS 13, *)
    lazy var basePublishers: BasePublishers = .init(controller: self)
    
    /// The type-erased delegate.
    var multicastDelegate: MulticastDelegate<AnyChatChannelWatcherListControllerDelegate<ExtraData>> = .init() {
        didSet {
            stateMulticastDelegate.mainDelegate = multicastDelegate.mainDelegate
            stateMulticastDelegate.additionalDelegates = multicastDelegate.additionalDelegates
            startObservingIfNeeded()
        }
    }
    
    /// The observer used to observe the changes in the database.
    private lazy var watchersObserver: ListDatabaseObserver<ChatUser, UserDTO> = createWatchersObserver()
    
    /// The worker used to fetch the remote data and communicate with servers.
    private lazy var updater: ChannelUpdater = self.environment.channelUpdaterBuilder(
        client.databaseContainer,
        client.apiClient
    )
    
    private let environment: Environment
    
    /// Creates a new `_ChatChannelWatcherListController`
    /// - Parameters:
    ///   - query: The query used for filtering and sorting the channel watchers.
    ///   - client: The `Client` this controller belongs to.
    ///   - environment: Environment for this controller.
    init(query: ChannelWatcherListQuery, client: ChatClient, environment: Environment = .init()) {
        self.client = client
        self.query = query
        self.environment = environment
    }
    
    /// Synchronizes the channel's watchers with the backend.
    /// - Parameter completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
        startObservingIfNeeded()
        
        if case let .localDataFetchFailed(error) = state {
            callback { completion?(error) }
            return
        }
        
        updater.channelWatchers(query: query) { error in
            self.state = error == nil ? .remoteDataFetched : .remoteDataFetchFailed(ClientError(with: error))
            self.callback { completion?(error) }
        }
    }
    
    /// Sets the provided object as a delegate of this controller.
    ///
    /// - Note: If you don't use custom extra data types, you can set the delegate directly using `controller.delegate = self`.
    /// Due to the current limits of Swift and the way it handles protocols with associated types, it's required to use this
    /// method to set the delegate, if you're using custom extra data types.
    ///
    /// - Parameter delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object
    /// alive if you want keep receiving updates.
    ///
    public func setDelegate<Delegate: _ChatChannelWatcherListControllerDelegate>(_ delegate: Delegate)
        where Delegate.ExtraData == ExtraData {
        multicastDelegate.mainDelegate = AnyChatChannelWatcherListControllerDelegate(delegate)
    }
    
    private func createWatchersObserver() -> ListDatabaseObserver<ChatUser, UserDTO> {
        let observer = environment.watcherListObserverBuilder(
            client.databaseContainer.viewContext,
            UserDTO.watcherFetchRequest(cid: query.cid),
            { $0.asModel() as ChatUser },
            NSFetchedResultsController<UserDTO>.self
        )
        
        observer.onChange = { [unowned self] changes in
            self.delegateCallback {
                $0.channelWatcherListController(self, didChangeWatchers: changes)
            }
        }
        
        return observer
    }
    
    private func startObservingIfNeeded() {
        guard state == .initialized else { return }
        
        do {
            try watchersObserver.startObserving()
            state = .localDataFetched
        } catch {
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
            state = .localDataFetchFailed(ClientError(with: error))
        }
    }
}

extension ChatChannelWatcherListController {
    struct Environment {
        var channelUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelUpdater = ChannelUpdater.init
        
        var watcherListObserverBuilder: (
            _ context: NSManagedObjectContext,
            _ fetchRequest: NSFetchRequest<UserDTO>,
            _ itemCreator: @escaping (UserDTO) -> ChatUser,
            _ controllerType: NSFetchedResultsController<UserDTO>.Type
        ) -> ListDatabaseObserver<ChatUser, UserDTO> = ListDatabaseObserver.init
    }
}

extension ChatChannelWatcherListController where ExtraData == NoExtraData {
    /// Set the delegate of `ChatChannelWatcherListController` to observe the changes in the system.
    ///
    /// - Note: The delegate can be set directly only if you're **not** using custom extra data types. Due to the current
    /// limits of Swift and the way it handles protocols with associated types, it's required to use `setDelegate` method
    /// instead to set the delegate, if you're using custom extra data types.
    public var delegate: ChatChannelWatcherListControllerDelegate? {
        get { multicastDelegate.mainDelegate?.wrappedDelegate as? ChatChannelWatcherListControllerDelegate }
        set { multicastDelegate.mainDelegate = AnyChatChannelWatcherListControllerDelegate(newValue) }
    }
}

public extension ChatChannelWatcherListController {
    /// Load next set of watchers from backend.
    ///
    /// - Parameters:
    ///   - limit: Limit for page size. Offset is defined automatically by the controller.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    func loadNextWatchers(limit: Int = .channelWatchersPageSize, completion: ((Error?) -> Void)? = nil) {
        var updatedQuery = query
        updatedQuery.pagination = .init(pageSize: limit, offset: watchers.count)
        updater.channelWatchers(query: updatedQuery) { error in
            self.query = updatedQuery
            self.callback { completion?(error) }
        }
    }
}

// MARK: - Delegates

/// `ChatChannelWatcherListController` uses this protocol to communicate changes to its delegate.
///
/// This protocol can be used only when no custom extra data are specified. If you're using custom extra data types,
/// please use `_ChatChannelWatcherListControllerDelegate` instead.
///
public protocol ChatChannelWatcherListControllerDelegate: DataControllerStateDelegate {
    /// The controller observed a change in the channel watcher list.
    func channelWatcherListController(
        _ controller: ChatChannelWatcherListController,
        didChangeWatchers changes: [ListChange<ChatUser>]
    )
}

public protocol _ChatChannelWatcherListControllerDelegate: DataControllerStateDelegate {
    associatedtype ExtraData: ExtraDataTypes
    
    /// The controller observed a change in the channel watcher list.
    func channelWatcherListController(
        _ controller: _ChatChannelWatcherListController<ExtraData>,
        didChangeWatchers changes: [ListChange<ChatUser>]
    )
}

// MARK: - Delegate type eraser

final class AnyChatChannelWatcherListControllerDelegate<ExtraData: ExtraDataTypes>: _ChatChannelWatcherListControllerDelegate {
    private let _controllerDidChangeState: (DataController, DataController.State) -> Void
    
    private let _controllerDidChangeWatchers: (
        _ChatChannelWatcherListController<ExtraData>,
        [ListChange<ChatUser>]
    ) -> Void
    
    weak var wrappedDelegate: AnyObject?
    
    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeState: @escaping (DataController, DataController.State) -> Void,
        controllerDidChangeWatchers: @escaping (
            _ChatChannelWatcherListController<ExtraData>,
            [ListChange<ChatUser>]
        ) -> Void
    ) {
        self.wrappedDelegate = wrappedDelegate
        _controllerDidChangeState = controllerDidChangeState
        _controllerDidChangeWatchers = controllerDidChangeWatchers
    }
    
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        _controllerDidChangeState(controller, state)
    }
    
    func channelWatcherListController(
        _ controller: _ChatChannelWatcherListController<ExtraData>,
        didChangeWatchers changes: [ListChange<ChatUser>]
    ) {
        _controllerDidChangeWatchers(controller, changes)
    }
}

extension AnyChatChannelWatcherListControllerDelegate {
    convenience init<Delegate: _ChatChannelWatcherListControllerDelegate>(_ delegate: Delegate)
        where Delegate.ExtraData == ExtraData {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in
                delegate?.controller($0, didChangeState: $1)
            },
            controllerDidChangeWatchers: { [weak delegate] in
                delegate?.channelWatcherListController($0, didChangeWatchers: $1)
            }
        )
    }
}

extension AnyChatChannelWatcherListControllerDelegate where ExtraData == NoExtraData {
    convenience init(_ delegate: ChatChannelWatcherListControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in
                delegate?.controller($0, didChangeState: $1)
            },
            controllerDidChangeWatchers: { [weak delegate] in
                delegate?.channelWatcherListController($0, didChangeWatchers: $1)
            }
        )
    }
}
