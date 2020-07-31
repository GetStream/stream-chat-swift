//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

extension Client {
    /// Creates a new `ChannelController` for the channel with the provided id and options.
    ///
    /// - Parameter channelId: The id of the channel this controller represents.
    /// - Parameter options: Query options (See `QueryOptions`)
    /// - Returns: A new instance of `ChannelController`.
    ///
    public func channelController(for channelId: ChannelId, options: QueryOptions = .all) -> ChannelControllerGeneric<ExtraData> {
        .init(channelQuery: .init(channelId: channelId, options: options), client: self)
    }
    
    /// Creates a new `ChannelController` for the channel with the provided id.
    ///
    /// - Parameter channelQuery: The ChannelQuery this controller represents
    /// - Returns: A new instance of `ChannelController`.
    ///
    public func channelController(for channelQuery: ChannelQuery<ExtraData>) -> ChannelControllerGeneric<ExtraData> {
        .init(channelQuery: channelQuery, client: self)
    }
}

/// A convenience typealias for `ChannelControllerGeneric` with `DefaultDataTypes`
public typealias ChannelController = ChannelControllerGeneric<DefaultDataTypes>

/// `ChannelController` allows observing and mutating the controlled channel.
///
///  ... you can do this and that
///
public class ChannelControllerGeneric<ExtraData: ExtraDataTypes>: Controller, DelegateCallbable {
    /// The ChannelQuery this controller observes.
    public let channelQuery: ChannelQuery<ExtraData>
    
    /// The `ChatClient` instance this controller belongs to.
    public let client: Client<ExtraData>
    
    /// The channel matching the channelId. To observe updates to the channel, set your class as a delegate of this controller and call `startUpdating`.
    public private(set) lazy var channel: ChannelModel<ExtraData>? = {
        log.warning("Accessing `channels` before calling `startUpdating()` always results in nil channel.")
        return nil
    }()
    
    /// The worker used to fetch the remote data and communicate with servers.
    private lazy var worker: ChannelUpdater<ExtraData> = self.environment.channelUpdaterBuilder(client.databaseContainer,
                                                                                                client.webSocketClient,
                                                                                                client.apiClient)
    
    /// A type-erased delegate.
    private(set) var anyDelegate: AnyChannelControllerDelegate<ExtraData>?
    
    /// Used for observing the database for changes.
    private(set) lazy var fetchResultsController: NSFetchedResultsController<ChannelDTO> = {
        let request = ChannelDTO.fetchRequest(for: channelQuery.cid)
        let frc = NSFetchedResultsController(fetchRequest: request,
                                             managedObjectContext: client.databaseContainer.viewContext,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        frc.delegate = self.changeAggregator
        return frc
    }()
    
    /// Acts like the `NSFetchedResultsController`'s delegate and aggregates the reported changes into easily consumable form.
    private(set) lazy var changeAggregator: ChangeAggregator<ChannelDTO, ChannelModel<ExtraData>> = {
        let aggregator: ChangeAggregator<ChannelDTO, ChannelModel<ExtraData>>
            = self.environment.changeAggregatorBuilder(ChannelModel<ExtraData>.create)
        
        aggregator.onChange = { [unowned self] (_: [Change<ChannelModel<ExtraData>>]) in
            guard let channel = self.fetchResultsController.fetchedObjects?.first
                .map(ChannelModel<ExtraData>.create(fromDTO:)) else { return }
            self.channel = channel
            self.delegateCallback {
                $0?.channelController(self, didUpdateChannel: channel)
            }
        }
        
        return aggregator
    }()
    
    private let environment: Environment
    
    /// Creates a new `ChannelController`
    /// - Parameters:
    ///   - channelQuery: channel query for observing changes
    ///   - client: The `Client` this controller belongs to.
    ///   - environment: Envrionment for this controller.
    init(channelQuery: ChannelQuery<ExtraData>, client: Client<ExtraData>, environment: Environment = .init()) {
        self.channelQuery = channelQuery
        self.client = client
        self.environment = environment
    }
    
    /// Starts updating the results.
    ///
    /// 1. **Synchronously** loads the data for the referenced objects from the local cache. These data are immediately available in
    /// the `channel` property of the controller once this method returns. Any further changes to the data are communicated
    /// using `delegate`.
    ///
    /// 2. It also **asynchronously** fetches the latest version of the data from the servers. Once the remote fetch is completed,
    /// the completion block is called. If the updated data differ from the locally cached ones, the controller uses the `delegate`
    /// methods to inform about the changes.
    ///
    /// - Parameter completion: Called when the controller has finished fetching remote data. If the data fetching fails, the `error`
    /// variable contains more details about the problem.
    public func startUpdating(_ completion: ((_ error: Error?) -> Void)? = nil) {
        do {
            try fetchResultsController.performFetch()
        } catch {
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
            completion?(ClientError.FetchFailed())
            return
        }
        
        channel = fetchResultsController.fetchedObjects?.first.map(ChannelModel<ExtraData>.create)
        
        delegateCallback {
            $0?.controllerWillStartFetchingRemoteData(self)
        }
        
        worker.update(channelQuery: channelQuery) { [weak self] error in
            guard let self = self else { return }
            self.delegateCallback {
                $0?.controllerDidStopFetchingRemoteData(self, withError: error)
            }
            completion?(error)
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
    public func setDelegate<Delegate: ChannelControllerDelegateGeneric>(_ delegate: Delegate)
        where Delegate.ExtraData == ExtraData {
        anyDelegate = AnyChannelControllerDelegate(delegate)
    }
}

extension ChannelControllerGeneric {
    struct Environment {
        var channelUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ webSocketClient: WebSocketClient,
            _ apiClient: APIClient
        ) -> ChannelUpdater<ExtraData> = ChannelUpdater.init
        
        var changeAggregatorBuilder: (_ itemBuilder: @escaping (ChannelDTO) -> ChannelModel<ExtraData>?)
            -> ChangeAggregator<ChannelDTO, ChannelModel<ExtraData>> = {
                ChangeAggregator<ChannelDTO, ChannelModel<ExtraData>>(itemCreator: $0)
            }
    }
}

public extension ChannelControllerGeneric where ExtraData == DefaultDataTypes {
    /// Set the delegate of `ChannelListController` to observe the changes in the system.
    ///
    /// - Note: The delegate can be set directly only if you're **not** using custom extra data types. Due to the current
    /// limits of Swift and the way it handles protocols with associated types, it's required to use `setDelegate` method
    /// instead to set the delegate, if you're using custom extra data types.
    var delegate: ChannelControllerDelegate? {
        set { anyDelegate = AnyChannelControllerDelegate(newValue) }
        get { anyDelegate?.wrappedDelegate as? ChannelControllerDelegate }
    }
}

// MARK: - Delegates

/// `ChannelController` uses this protocol to communicate changes to its delegate.
///
/// This protocol can be used only when no custom extra data are specified. If you're using custom extra data types,
/// please use `ChannelControllerDelegateGeneric` instead.
public protocol ChannelControllerDelegate: ControllerRemoteActivityDelegate {
    func channelController(_ channelController: ChannelController,
                           didUpdateChannel channel: Channel)
}

public extension ChannelControllerDelegate {
    func channelController(_ channelController: ChannelController,
                           didUpdateChannel channel: Channel) {}
}

// MARK: Generic Delegates

/// `ChannelController` uses this protocol to communicate changes to its delegate.
///
/// If you're **not** using custom extra data types, you can use a convenience version of this protocol
/// named `ChannelControllerDelegate`, which hides the generic types, and make the usage easier.
public protocol ChannelControllerDelegateGeneric: ControllerRemoteActivityDelegate {
    associatedtype ExtraData: ExtraDataTypes
    func channelController(_ channelController: ChannelControllerGeneric<ExtraData>,
                           didUpdateChannel channel: ChannelModel<ExtraData>)
}

public extension ChannelControllerDelegateGeneric {
    func channelController(_ channelController: ChannelControllerGeneric<ExtraData>,
                           didUpdateChannel channel: ChannelModel<ExtraData>) {}
}

// MARK: Type erased Delegate

class AnyChannelControllerDelegate<ExtraData: ExtraDataTypes>: ChannelListControllerDelegateGeneric {
    private var _controllerDidUpdateChannel: (ChannelControllerGeneric<ExtraData>, ChannelModel<ExtraData>) -> Void
    private var _controllerWillStartFetchingRemoteData: (Controller) -> Void
    private var _controllerDidStopFetchingRemoteData: (Controller, Error?) -> Void
    
    weak var wrappedDelegate: AnyObject?
    
    init(
        wrappedDelegate: AnyObject?,
        controllerWillStartFetchingRemoteData: @escaping (Controller) -> Void,
        controllerDidStopFetchingRemoteData: @escaping (Controller, Error?) -> Void,
        controllerDidUpdateChannel: @escaping (ChannelControllerGeneric<ExtraData>, ChannelModel<ExtraData>) -> Void
    ) {
        self.wrappedDelegate = wrappedDelegate
        _controllerWillStartFetchingRemoteData = controllerWillStartFetchingRemoteData
        _controllerDidStopFetchingRemoteData = controllerDidStopFetchingRemoteData
        _controllerDidUpdateChannel = controllerDidUpdateChannel
    }
    
    func controllerWillStartFetchingRemoteData(_ controller: Controller) {
        _controllerWillStartFetchingRemoteData(controller)
    }
    
    func controllerDidStopFetchingRemoteData(_ controller: Controller, withError error: Error?) {
        _controllerDidStopFetchingRemoteData(controller, error)
    }
    
    func channelController(
        _ controller: ChannelControllerGeneric<ExtraData>,
        didUpdateChannel channel: ChannelModel<ExtraData>
    ) {
        _controllerDidUpdateChannel(controller, channel)
    }
}

extension AnyChannelControllerDelegate {
    convenience init<Delegate: ChannelControllerDelegateGeneric>(_ delegate: Delegate) where Delegate.ExtraData == ExtraData {
        self.init(wrappedDelegate: delegate,
                  controllerWillStartFetchingRemoteData: { [weak delegate] in delegate?.controllerWillStartFetchingRemoteData($0) },
                  controllerDidStopFetchingRemoteData: { [weak delegate] in
                      delegate?.controllerDidStopFetchingRemoteData($0, withError: $1)
                  },
                  controllerDidUpdateChannel: { [weak delegate] in delegate?.channelController($0, didUpdateChannel: $1) })
    }
}

extension AnyChannelControllerDelegate where ExtraData == DefaultDataTypes {
    convenience init(_ delegate: ChannelControllerDelegate?) {
        self.init(wrappedDelegate: delegate,
                  controllerWillStartFetchingRemoteData: { [weak delegate] in delegate?.controllerWillStartFetchingRemoteData($0) },
                  controllerDidStopFetchingRemoteData: { [weak delegate] in
                      delegate?.controllerDidStopFetchingRemoteData($0, withError: $1)
                  },
                  controllerDidUpdateChannel: { [weak delegate] in delegate?.channelController($0, didUpdateChannel: $1) })
    }
}
