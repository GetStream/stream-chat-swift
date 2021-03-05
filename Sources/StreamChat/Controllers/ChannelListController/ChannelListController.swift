//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

extension _ChatClient {
    /// Creates a new `ChannelListController` with the provided channel query.
    ///
    /// - Parameter query: The query specify the filter and sorting of the channels the controller should fetch.
    ///
    /// - Returns: A new instance of `ChannelController`.
    ///
    public func channelListController(query: _ChannelListQuery<ExtraData.Channel>) -> _ChatChannelListController<ExtraData> {
        .init(query: query, client: self)
    }
}

/// `_ChatChannelListController` is a controller class which allows observing a list of chat channels based on the provided query.
///
/// Learn more about `_ChatChannelListController` and its usage in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#channel-list).
///
/// - Note: `ChatChannelListController` is a typealias of `_ChatChannelListController` with default extra data. If you're using
/// custom extra data, create your own typealias of `_ChatChannelListController`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public typealias ChatChannelListController = _ChatChannelListController<NoExtraData>

/// `_ChatChannelListController` is a controller class which allows observing a list of chat channels based on the provided query.
///
/// Learn more about `_ChatChannelListController` and its usage in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#channel-list).
///
/// - Note: `_ChatChannelListController` type is not meant to be used directly. If you're using default extra data, use
/// `ChatChannelController` typealias instead. If you're using custom extra data, create your own typealias
/// of `_ChatChannelListController`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public class _ChatChannelListController<ExtraData: ExtraDataTypes>: DataController, DelegateCallable, DataStoreProvider {
    /// The query specifying and filtering the list of channels.
    public let query: _ChannelListQuery<ExtraData.Channel>
    
    /// The `ChatClient` instance this controller belongs to.
    public let client: _ChatClient<ExtraData>
    
    /// The channels matching the query of this controller.
    ///
    /// To observe changes of the channels, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    ///
    public var channels: LazyCachedMapCollection<_ChatChannel<ExtraData>> { channelListObserver.items }
    
    /// The worker used to fetch the remote data and communicate with servers.
    private lazy var worker: ChannelListUpdater<ExtraData> = self.environment
        .channelQueryUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<AnyChannelListControllerDelegate<ExtraData>> = .init() {
        didSet {
            stateMulticastDelegate.mainDelegate = multicastDelegate.mainDelegate
            stateMulticastDelegate.additionalDelegates = multicastDelegate.additionalDelegates
            
            // After setting delegate local changes will be fetched and observed.
            startChannelListObserver()
        }
    }
    
    /// Used for observing the database for changes.
    private(set) lazy var channelListObserver: ListDatabaseObserver<_ChatChannel<ExtraData>, ChannelDTO> = {
        let request = ChannelDTO.channelListFetchRequest(query: self.query)
        
        let observer = self.environment.createChannelListDabaseObserver(
            client.databaseContainer.viewContext,
            request,
            { $0.asModel() }
        )
        
        observer.onChange = { [unowned self] changes in
            self.delegateCallback {
                $0.controller(self, didChangeChannels: changes)
            }
        }
        
        do {
            try observer.startObserving()
            state = .localDataFetched
        } catch {
            state = .localDataFetchFailed(ClientError(with: error))
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
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
    init(query: _ChannelListQuery<ExtraData.Channel>, client: _ChatClient<ExtraData>, environment: Environment = .init()) {
        self.client = client
        self.query = query
        self.environment = environment
    }
    
    override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
        worker.update(channelListQuery: query) { error in
            self.state = error == nil ? .remoteDataFetched : .remoteDataFetchFailed(ClientError(with: error))
            self.callback { completion?(error) }
        }
    }
    
    /// Initializing of `channelListObserver` will start local data observing.
    /// In most cases it will be done by accessing `channels` but it's possible that only
    /// changes will be observed.
    private func startChannelListObserver() {
        _ = channelListObserver
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
    public func setDelegate<Delegate: _ChatChannelListControllerDelegate>(_ delegate: Delegate)
        where Delegate.ExtraData == ExtraData {
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
        limit: Int = 25,
        completion: ((Error?) -> Void)? = nil
    ) {
        var updatedQuery = query
        updatedQuery.pagination = Pagination(pageSize: limit, offset: channels.count)
        worker.update(channelListQuery: updatedQuery) { error in
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
}

extension _ChatChannelListController {
    struct Environment {
        var channelQueryUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelListUpdater<ExtraData> = ChannelListUpdater.init

        var createChannelListDabaseObserver: (
            _ context: NSManagedObjectContext,
            _ fetchRequest: NSFetchRequest<ChannelDTO>,
            _ itemCreator: @escaping (ChannelDTO) -> _ChatChannel<ExtraData>
        )
            -> ListDatabaseObserver<_ChatChannel<ExtraData>, ChannelDTO> = {
                ListDatabaseObserver(context: $0, fetchRequest: $1, itemCreator: $2)
            }
    }
}

extension _ChatChannelListController where ExtraData == NoExtraData {
    /// Set the delegate of `ChannelListController` to observe the changes in the system.
    ///
    /// - Note: The delegate can be set directly only if you're **not** using custom extra data types. Due to the current
    /// limits of Swift and the way it handles protocols with associated types, it's required to use `setDelegate` method
    /// instead to set the delegate, if you're using custom extra data types.
    public weak var delegate: ChatChannelListControllerDelegate? {
        get { multicastDelegate.mainDelegate?.wrappedDelegate as? ChatChannelListControllerDelegate }
        set { multicastDelegate.mainDelegate = AnyChannelListControllerDelegate(newValue) }
    }
}

/// `ChatChannelListController` uses this protocol to communicate changes to its delegate.
///
/// This protocol can be used only when no custom extra data are specified. If you're using custom extra data types,
/// please use `_ChatChannelListControllerDelegate` instead.
///
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
        _ controller: _ChatChannelListController<NoExtraData>,
        didChangeChannels changes: [ListChange<ChatChannel>]
    ) {}
}

/// `ChatChannelListController` uses this protocol to communicate changes to its delegate.
///
/// If you're **not** using custom extra data types, you can use a convenience version of this protocol
/// named `ChatChannelListControllerDelegate`, which hides the generic types, and make the usage easier.
///
public protocol _ChatChannelListControllerDelegate: DataControllerStateDelegate {
    associatedtype ExtraData: ExtraDataTypes
    
    /// The controller changed the list of observed channels.
    ///
    /// - Parameters:
    ///   - controller: The controller emitting the change callback.
    ///   - changes: The change to the list of channels.\
    ///
    func controller(
        _ controller: _ChatChannelListController<ExtraData>,
        didChangeChannels changes: [ListChange<_ChatChannel<ExtraData>>]
    )
}

public extension _ChatChannelListControllerDelegate {
    func controller(
        _ controller: _ChatChannelListController<ExtraData>,
        didChangeChannels changes: [ListChange<_ChatChannel<ExtraData>>]
    ) {}
}

extension ClientError {
    public class FetchFailed: Error {
        public var localizedDescription: String = "Failed to perform fetch request. This is an internal error."
    }
}

// MARK: - Delegate type eraser

class AnyChannelListControllerDelegate<ExtraData: ExtraDataTypes>: _ChatChannelListControllerDelegate {
    private var _controllerDidChangeChannels: (_ChatChannelListController<ExtraData>, [ListChange<_ChatChannel<ExtraData>>])
        -> Void
    private var _controllerDidChangeState: (DataController, DataController.State) -> Void
    
    weak var wrappedDelegate: AnyObject?
    
    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeState: @escaping (DataController, DataController.State) -> Void,
        controllerDidChangeChannels: @escaping (_ChatChannelListController<ExtraData>, [ListChange<_ChatChannel<ExtraData>>])
            -> Void
    ) {
        self.wrappedDelegate = wrappedDelegate
        _controllerDidChangeState = controllerDidChangeState
        _controllerDidChangeChannels = controllerDidChangeChannels
    }

    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        _controllerDidChangeState(controller, state)
    }

    func controller(
        _ controller: _ChatChannelListController<ExtraData>,
        didChangeChannels changes: [ListChange<_ChatChannel<ExtraData>>]
    ) {
        _controllerDidChangeChannels(controller, changes)
    }
}

extension AnyChannelListControllerDelegate {
    convenience init<Delegate: _ChatChannelListControllerDelegate>(_ delegate: Delegate) where Delegate.ExtraData == ExtraData {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidChangeChannels: { [weak delegate] in delegate?.controller($0, didChangeChannels: $1) }
        )
    }
}

extension AnyChannelListControllerDelegate where ExtraData == NoExtraData {
    convenience init(_ delegate: ChatChannelListControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidChangeChannels: { [weak delegate] in delegate?.controller($0, didChangeChannels: $1) }
        )
    }
}
