//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

extension Client {
    /// Creates a new `ChannelListController` with the provided channel query.
    ///
    /// - Parameter query: The query specify the filter and sorting of the channels the controller should fetch.
    /// - Returns: A new instance of `ChannelController`.
    ///
    public func channelListController(query: ChannelListQuery) -> ChannelListControllerGeneric<ExtraData> {
        .init(query: query, client: self)
    }
}

/// A convenience typealias for `ChannelListControllerGeneric` with `DefaultDataTypes`
public typealias ChannelListController = ChannelListControllerGeneric<DefaultDataTypes>

/// `ChannelListController` allows observing and mutating the list of channels specified by a channel query.
///
///  ... you can do this and that
///
public class ChannelListControllerGeneric<ExtraData: ExtraDataTypes>: Controller, DelegateCallable, DataStoreProvider {
    /// The query specifying and filtering the list of channels.
    public let query: ChannelListQuery
    
    /// The `ChatClient` instance this controller belongs to.
    public let client: Client<ExtraData>
    
    /// The channels matching the query. To observe updates in the list, set your class as a delegate of this controller.
    public var channels: [ChannelModel<ExtraData>] {
        guard state != .inactive else {
            log.warning("Accessing `channels` before calling `startUpdating()` always results in an empty array.")
            return []
        }
        
        return channelListObserver.items
    }
    
    /// The worker used to fetch the remote data and communicate with servers.
    private lazy var worker: ChannelListUpdater<ExtraData> = self.environment
        .channelQueryUpdaterBuilder(
            client.databaseContainer,
            client.webSocketClient,
            client.apiClient
        )

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<AnyChannelListControllerDelegate<ExtraData>> = .init() {
        didSet {
            stateMulticastDelegate.mainDelegate = multicastDelegate.mainDelegate
            stateMulticastDelegate.additionalDelegates = multicastDelegate.additionalDelegates
        }
    }
    
    /// Used for observing the database for changes.
    private(set) lazy var channelListObserver: ListDatabaseObserver<ChannelModel<ExtraData>, ChannelDTO> = {
        let request = ChannelDTO.channelListFetchRequest(query: self.query)
        
        let observer = self.environment.createChannelListDabaseObserver(
            client.databaseContainer.viewContext,
            request,
            ChannelModel<ExtraData>.create
        )
        
        observer.onChange = { [unowned self] changes in
            self.delegateCallback {
                $0.controller(self, didChangeChannels: changes)
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
    init(query: ChannelListQuery, client: Client<ExtraData>, environment: Environment = .init()) {
        self.client = client
        self.query = query
        self.environment = environment
    }
    
    /// Starts updating the results.
    ///
    /// 1. **Synchronously** loads the data for the referenced objects from the local cache. These data are immediately available in
    /// the `channels` property of the controller once this method returns. Any further changes to the data are communicated
    /// using `delegate`.
    ///
    /// 2. It also **asynchronously** fetches the latest version of the data from the servers. Once the remote fetch is completed,
    /// the completion block is called. If the updated data differ from the locally cached ones, the controller uses the `delegate`
    /// methods to inform about the changes.
    ///
    /// - Parameter completion: Called when the controller has finished fetching remote data.
    ///                         If the data fetching fails, the `error` variable contains more details about the problem.
    public func startUpdating(_ completion: ((_ error: Error?) -> Void)? = nil) {
        do {
            try channelListObserver.startObserving()
        } catch {
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
            callback { completion?(ClientError.FetchFailed()) }
            return
        }

        // Update observing state
        state = .localDataFetched
        
        worker.update(channelListQuery: query) { [weak self] error in
            guard let self = self else { return }
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
    public func setDelegate<Delegate: ChannelListControllerDelegateGeneric>(_ delegate: Delegate)
        where Delegate.ExtraData == ExtraData {
        multicastDelegate.mainDelegate = AnyChannelListControllerDelegate(delegate)
    }
}

// MARK: - Actions

public extension ChannelListControllerGeneric {
    /// Loads next channels from backend.
    /// - Parameters:
    ///   - limit: Limit for page size.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    func loadNextChannels(
        limit: Int = 25,
        completion: ((Error?) -> Void)? = nil
    ) {
        var updatedQuery = query
        updatedQuery.pagination = [.limit(limit), .offset(channels.count)]
        worker.update(channelListQuery: updatedQuery) { [weak self] error in
            self?.callback { completion?(error) }
        }
    }
    
    /// Marks all channels for a user as read.
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func markAllRead(completion: ((Error?) -> Void)? = nil) {
        worker.markAllRead { [weak self] error in
            self?.callback {
                completion?(error)
            }
        }
    }
}

extension ChannelListControllerGeneric {
    struct Environment {
        var channelQueryUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ webSocketClient: WebSocketClient,
            _ apiClient: APIClient
        ) -> ChannelListUpdater<ExtraData> = ChannelListUpdater.init

        var createChannelListDabaseObserver: (
            _ context: NSManagedObjectContext,
            _ fetchRequest: NSFetchRequest<ChannelDTO>,
            _ itemCreator: @escaping (ChannelDTO) -> ChannelModel<ExtraData>?
        )
            -> ListDatabaseObserver<ChannelModel<ExtraData>, ChannelDTO> = {
                ListDatabaseObserver(context: $0, fetchRequest: $1, itemCreator: $2)
            }
    }
}

extension ChannelListControllerGeneric where ExtraData == DefaultDataTypes {
    /// Set the delegate of `ChannelListController` to observe the changes in the system.
    ///
    /// - Note: The delegate can be set directly only if you're **not** using custom extra data types. Due to the current
    /// limits of Swift and the way it handles protocols with associated types, it's required to use `setDelegate` method
    /// instead to set the delegate, if you're using custom extra data types.
    public weak var delegate: ChannelListControllerDelegate? {
        set { multicastDelegate.mainDelegate = AnyChannelListControllerDelegate(newValue) }
        get { multicastDelegate.mainDelegate?.wrappedDelegate as? ChannelListControllerDelegate }
    }
}

/// `ChannelListController` uses this protocol to communicate changes to its delegate.
///
/// This protocol can be used only when no custom extra data are specified. If you're using custom extra data types,
/// please use `GenericChannelListController` instead.
public protocol ChannelListControllerDelegate: ControllerStateDelegate {
    func controller(_ controller: ChannelListControllerGeneric<DefaultDataTypes>, didChangeChannels changes: [ListChange<Channel>])
}

public extension ChannelListControllerDelegate {
    func controller(
        _ controller: ChannelListControllerGeneric<DefaultDataTypes>,
        didChangeChannels changes: [ListChange<Channel>]
    ) {}
}

/// `ChannelListController` uses this protocol to communicate changes to its delegate.
///
/// If you're **not** using custom extra data types, you can use a convenience version of this protocol
/// named `ChannelListControllerDelegate`, which hides the generic types, and make the usage easier.
public protocol ChannelListControllerDelegateGeneric: ControllerStateDelegate {
    associatedtype ExtraData: ExtraDataTypes
    func controller(
        _ controller: ChannelListControllerGeneric<ExtraData>,
        didChangeChannels changes: [ListChange<ChannelModel<ExtraData>>]
    )
}

public extension ChannelListControllerDelegateGeneric {
    func controller(
        _ controller: ChannelListControllerGeneric<DefaultDataTypes>,
        didChangeChannels changes: [ListChange<ChannelModel<ExtraData>>]
    ) {}
}

extension ClientError {
    public class FetchFailed: Error {
        public var localizedDescription: String = "Failed to perform fetch request. This is an internal error."
    }
}

// MARK: - Delegate type eraser

class AnyChannelListControllerDelegate<ExtraData: ExtraDataTypes>: ChannelListControllerDelegateGeneric {
    private var _controllerDidChangeChannels: (ChannelListControllerGeneric<ExtraData>, [ListChange<ChannelModel<ExtraData>>])
        -> Void
    private var _controllerDidChangeState: (Controller, Controller.State) -> Void
    
    weak var wrappedDelegate: AnyObject?
    
    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeState: @escaping (Controller, Controller.State) -> Void,
        controllerDidChangeChannels: @escaping (ChannelListControllerGeneric<ExtraData>, [ListChange<ChannelModel<ExtraData>>])
            -> Void
    ) {
        self.wrappedDelegate = wrappedDelegate
        _controllerDidChangeState = controllerDidChangeState
        _controllerDidChangeChannels = controllerDidChangeChannels
    }

    func controller(_ controller: Controller, didChangeState state: Controller.State) {
        _controllerDidChangeState(controller, state)
    }

    func controller(
        _ controller: ChannelListControllerGeneric<ExtraData>,
        didChangeChannels changes: [ListChange<ChannelModel<ExtraData>>]
    ) {
        _controllerDidChangeChannels(controller, changes)
    }
}

extension AnyChannelListControllerDelegate {
    convenience init<Delegate: ChannelListControllerDelegateGeneric>(_ delegate: Delegate) where Delegate.ExtraData == ExtraData {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidChangeChannels: { [weak delegate] in delegate?.controller($0, didChangeChannels: $1) }
        )
    }
}

extension AnyChannelListControllerDelegate where ExtraData == DefaultDataTypes {
    convenience init(_ delegate: ChannelListControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidChangeChannels: { [weak delegate] in delegate?.controller($0, didChangeChannels: $1) }
        )
    }
}
