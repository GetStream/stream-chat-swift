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
public class ChannelControllerGeneric<ExtraData: ExtraDataTypes>: Controller, DelegateCallable {
    /// The ChannelQuery this controller observes.
    public let channelQuery: ChannelQuery<ExtraData>
    
    /// The `ChatClient` instance this controller belongs to.
    public let client: Client<ExtraData>
    
    /// The channel matching the channelId. To observe updates to the channel, set your class as a delegate of this controller and call `startUpdating`.
    public var channel: ChannelModel<ExtraData>? {
        guard state == .active else {
            log.warning("Accessing `channel` before calling `startUpdating()` always results in `nil`.")
            return nil
        }
        
        return channelObserver.item
    }
    
    /// The channel matching the channelId. To observe updates to the channel, set your class as a delegate of this controller and call `startUpdating`.
    public var messages: [MessageModel<ExtraData>] {
        guard state == .active else {
            log.warning("Accessing `messages` before calling `startUpdating()` always results in an empty array.")
            return []
        }
        
        return messagesObserver.items
    }
    
    /// The worker used to fetch the remote data and communicate with servers.
    private lazy var channelUpdater: ChannelUpdater<ExtraData> = self.environment.channelUpdaterBuilder(client.databaseContainer,
                                                                                                        client.webSocketClient,
                                                                                                        client.apiClient)
    
    /// A type-erased delegate.
    private(set) var anyDelegate: AnyChannelControllerDelegate<ExtraData>?
    
    private(set) lazy var channelObserver: EntityDatabaseObserver<ChannelModel<ExtraData>, ChannelDTO> = {
        let observer = EntityDatabaseObserver(context: self.client.databaseContainer.viewContext,
                                              fetchRequest: ChannelDTO.fetchRequest(for: self.channelQuery.cid),
                                              itemCreator: ChannelModel<ExtraData>.create)
        observer.onChange = { [unowned self] change in
            self.delegateCallback { $0?.channelController(self, didUpdateChannel: change) }
        }
        
        return observer
    }()
    
    private(set) lazy var messagesObserver: ListDatabaseObserver<MessageModel<ExtraData>, MessageDTO> = {
        let observer = ListDatabaseObserver(context: self.client.databaseContainer.viewContext,
                                            fetchRequest: MessageDTO.messagesFetchRequest(for: self.channelQuery.cid),
                                            itemCreator: MessageModel<ExtraData>.init)
        observer.onChange = { [unowned self] changes in
            self.delegateCallback {
                $0?.channelController(self, didUpdateMessages: changes)
            }
        }
        
        return observer
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
            try channelObserver.startObserving()
            try messagesObserver.startObserving()
        } catch {
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
            callback { completion?(ClientError.FetchFailed()) }
            return
        }
        
        state = .active
        
        delegateCallback {
            $0?.controllerWillStartFetchingRemoteData(self)
        }
        
        channelUpdater.update(channelQuery: channelQuery) { [weak self] error in
            guard let self = self else { return }
            self.delegateCallback { $0?.controllerDidStopFetchingRemoteData(self, withError: error) }
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
    public func setDelegate<Delegate: ChannelControllerDelegateGeneric>(_ delegate: Delegate)
        where Delegate.ExtraData == ExtraData {
        anyDelegate = AnyChannelControllerDelegate(delegate)
    }
}

// MARK: - Channel actions

public extension ChannelControllerGeneric {
    /// Mutes the channel with provided **cid**.
    /// - Parameters:
    ///   - cid: The channel identifier.
    ///   - completion: Called when the channel is muted. If the api-call fails, the completion
    /// is called with an error.
    func muteChannel(cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        channelUpdater.muteChannel(cid: cid, mute: true) { [weak self] error in
            self?.callbackQueue.async {
                completion?(error)
            }
        }
    }

    /// Unmutes the channel with provided **cid**.
    /// - Parameters:
    ///   - cid: The channel identifier.
    ///   - completion: Called when the channel is unmuted. If the api-call fails, the completion
    /// is called with an error.
    func unmuteChannel(cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        channelUpdater.muteChannel(cid: cid, mute: false) { [weak self] error in
            self?.callbackQueue.async {
                completion?(error)
            }
        }
    }

    /// Delete the channel.
    /// - Parameters:
    ///   - channel: The channel you want to delete.
    ///   - completion: An empty completion block.
    func deleteChannel(cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        channelUpdater.deleteChannel(cid: cid) { [weak self] error in
            self?.callbackQueue.async {
                completion?(error)
            }
        }
    }

    /// Hide the channel from queryChannels for the user until a message is added.
    /// - Parameters:
    ///   - channel: The channel you want to hide.
    ///   - userId: Current user Id.
    ///   - clearHistory: Flag to remove channel history.
    ///   - completion: An empty completion block.
    func hideChannel(cid: ChannelId, clearHistory: Bool, completion: ((Error?) -> Void)? = nil) {
        channelUpdater.hideChannel(cid: cid, userId: client.currentUserId, clearHistory: clearHistory) { [weak self] error in
            self?.callbackQueue.async {
                completion?(error)
            }
        }
    }

    /// Removes hidden status for the specific channel.
    /// - Parameters:
    ///   - channel: The channel you want to show.
    ///   - userId: Current user Id.
    ///   - completion: An empty completion block.
    func showChannel(cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        channelUpdater.showChannel(cid: cid, userId: client.currentUserId) { [weak self] error in
            self?.callbackQueue.async {
                completion?(error)
            }
        }
    }
}


extension ChannelControllerGeneric {
    struct Environment {
        var channelUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ webSocketClient: WebSocketClient,
            _ apiClient: APIClient
        ) -> ChannelUpdater<ExtraData> = ChannelUpdater.init
    }
}

public extension ChannelControllerGeneric where ExtraData == DefaultDataTypes {
    /// Set the delegate of `ChannelController` to observe the changes in the system.
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
    /// The controller observed a change in the `Channel` entity.
    func channelController(_ channelController: ChannelController,
                           didUpdateChannel channel: EntityChange<Channel>)
    
    /// The controller observed changes in the `Messages` of the observed channel.
    func channelController(_ channelController: ChannelController,
                           didUpdateMessages changes: [ListChange<Message>])
}

public extension ChannelControllerDelegate {
    func channelController(_ channelController: ChannelController,
                           didUpdateChannel channel: EntityChange<Channel>) {}
    
    func channelController(_ channelController: ChannelController,
                           didUpdateMessages changes: [ListChange<Message>]) {}
}

// MARK: Generic Delegates

/// `ChannelController` uses this protocol to communicate changes to its delegate.
///
/// If you're **not** using custom extra data types, you can use a convenience version of this protocol
/// named `ChannelControllerDelegate`, which hides the generic types, and make the usage easier.
public protocol ChannelControllerDelegateGeneric: ControllerRemoteActivityDelegate {
    associatedtype ExtraData: ExtraDataTypes
    
    /// The controller observed a change in the `Channel` entity.
    func channelController(_ channelController: ChannelControllerGeneric<ExtraData>,
                           didUpdateChannel channel: EntityChange<ChannelModel<ExtraData>>)
    
    /// The controller observed changes in the `Messages` of the observed channel.
    func channelController(_ channelController: ChannelControllerGeneric<ExtraData>,
                           didUpdateMessages changes: [ListChange<MessageModel<ExtraData>>])
}

public extension ChannelControllerDelegateGeneric {
    func channelController(_ channelController: ChannelControllerGeneric<ExtraData>,
                           didUpdateChannel channel: EntityChange<ChannelModel<ExtraData>>) {}
    
    func channelController(_ channelController: ChannelController,
                           didUpdateMessages changes: [ListChange<MessageModel<ExtraData>>]) {}
}

// MARK: Type erased Delegate

class AnyChannelControllerDelegate<ExtraData: ExtraDataTypes>: ChannelListControllerDelegateGeneric {
    private var _controllerdidUpdateMessages: (ChannelControllerGeneric<ExtraData>,
                                               [ListChange<MessageModel<ExtraData>>]) -> Void
    
    private var _controllerDidUpdateChannel: (ChannelControllerGeneric<ExtraData>,
                                              EntityChange<ChannelModel<ExtraData>>) -> Void
    
    private var _controllerWillStartFetchingRemoteData: (Controller) -> Void
    private var _controllerDidStopFetchingRemoteData: (Controller, Error?) -> Void
    
    weak var wrappedDelegate: AnyObject?
    
    init(
        wrappedDelegate: AnyObject?,
        controllerWillStartFetchingRemoteData: @escaping (Controller) -> Void,
        controllerDidStopFetchingRemoteData: @escaping (Controller, Error?) -> Void,
        controllerDidUpdateChannel: @escaping (ChannelControllerGeneric<ExtraData>,
                                               EntityChange<ChannelModel<ExtraData>>) -> Void,
        controllerdidUpdateMessages: @escaping (ChannelControllerGeneric<ExtraData>,
                                                [ListChange<MessageModel<ExtraData>>]) -> Void
    ) {
        self.wrappedDelegate = wrappedDelegate
        _controllerWillStartFetchingRemoteData = controllerWillStartFetchingRemoteData
        _controllerDidStopFetchingRemoteData = controllerDidStopFetchingRemoteData
        _controllerDidUpdateChannel = controllerDidUpdateChannel
        _controllerdidUpdateMessages = controllerdidUpdateMessages
    }
    
    func controllerWillStartFetchingRemoteData(_ controller: Controller) {
        _controllerWillStartFetchingRemoteData(controller)
    }
    
    func controllerDidStopFetchingRemoteData(_ controller: Controller, withError error: Error?) {
        _controllerDidStopFetchingRemoteData(controller, error)
    }
    
    func channelController(
        _ controller: ChannelControllerGeneric<ExtraData>,
        didUpdateChannel channel: EntityChange<ChannelModel<ExtraData>>
    ) {
        _controllerDidUpdateChannel(controller, channel)
    }
    
    func channelController(
        _ controller: ChannelControllerGeneric<ExtraData>,
        didUpdateMessages changes: [ListChange<MessageModel<ExtraData>>]
    ) {
        _controllerdidUpdateMessages(controller, changes)
    }
}

extension AnyChannelControllerDelegate {
    convenience init<Delegate: ChannelControllerDelegateGeneric>(_ delegate: Delegate) where Delegate.ExtraData == ExtraData {
        self.init(wrappedDelegate: delegate,
                  controllerWillStartFetchingRemoteData: { [weak delegate] in delegate?.controllerWillStartFetchingRemoteData($0) },
                  controllerDidStopFetchingRemoteData: { [weak delegate] in
                      delegate?.controllerDidStopFetchingRemoteData($0, withError: $1)
                  },
                  controllerDidUpdateChannel: { [weak delegate] in delegate?.channelController($0, didUpdateChannel: $1) },
                  controllerdidUpdateMessages: { [weak delegate] in delegate?.channelController($0, didUpdateMessages: $1) })
    }
}

extension AnyChannelControllerDelegate where ExtraData == DefaultDataTypes {
    convenience init(_ delegate: ChannelControllerDelegate?) {
        self.init(wrappedDelegate: delegate,
                  controllerWillStartFetchingRemoteData: { [weak delegate] in delegate?.controllerWillStartFetchingRemoteData($0) },
                  controllerDidStopFetchingRemoteData: { [weak delegate] in
                      delegate?.controllerDidStopFetchingRemoteData($0, withError: $1)
                  },
                  controllerDidUpdateChannel: { [weak delegate] in delegate?.channelController($0, didUpdateChannel: $1) },
                  controllerdidUpdateMessages: { [weak delegate] in delegate?.channelController($0, didUpdateMessages: $1) })
    }
}
