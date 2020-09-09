//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public extension Client {
    /// Creates a new `ConnectionControllerGeneric`
    /// - Parameter callbackQueue: a callback queue for the delgate.
    /// - Returns: A new instance of `ConnectionControllerGeneric`.
    func connectionController(callbackQueue: DispatchQueue? = nil) -> ConnectionControllerGeneric<ExtraData> {
        .init(client: self, callbackQueue: callbackQueue)
    }
}

/// A convenience typealias for `ConnectionControllerGeneric` with `DefaultDataTypes`
public typealias ConnectionController = ConnectionControllerGeneric<DefaultDataTypes>

/// A connection controller to get connection status updates.
public class ConnectionControllerGeneric<ExtraData: ExtraDataTypes> {
    /// The `Client` instance this controller belongs to.
    public let client: Client<ExtraData>
    
    /// The current connection status of the client.
    public var connectionStatus: ConnectionStatus { .init(webSocketConnectionState: client.webSocketClient.connectionState) }
    
    /// A delegate to get connection status updates.
    public weak var delegate: ConnectionControllerDelegate?
    
    /// A callback queue in which the delegate will be called.
    public let callbackQueue: DispatchQueue?
    
    /// The connection event observer for the connection status updates.
    private lazy var connectionEventObserver: ConnectionEventObserver = {
        .init(notificationCenter: client.webSocketClient.eventNotificationCenter) { [weak self] in
            guard let self = self else { return }
            let connectionStatus = $0.connectionStatus
            
            if let callbackQueue = self.callbackQueue {
                callbackQueue.async { self.delegate?.controller(self, didUpdateConnectionStatus: connectionStatus) }
            } else {
                self.delegate?.controller(self, didUpdateConnectionStatus: connectionStatus)
            }
        }
    }()
    
    init(client: Client<ExtraData>, callbackQueue: DispatchQueue? = nil) {
        self.client = client
        self.callbackQueue = callbackQueue
        _ = connectionEventObserver
    }
}

/// A connection controller delegate to get connection status updates.
public protocol ConnectionControllerDelegate: class {
    /// Calls on a new client connection status.
    /// - Parameters:
    ///   - controller: a connection controller.
    ///   - status: a connection status.
    func controller<ExtraData: ExtraDataTypes>(
        _ controller: ConnectionControllerGeneric<ExtraData>,
        didUpdateConnectionStatus status: ConnectionStatus
    )
}

/// A connection event observer to handle `ConnectionStatusUpdated` events.
class ConnectionEventObserver: EventObserver {
    init(
        notificationCenter: NotificationCenter,
        filter: ((ConnectionStatusUpdated) -> Bool)? = nil,
        callback: @escaping (ConnectionStatusUpdated) -> Void
    ) {
        super.init(notificationCenter: notificationCenter, tranform: { $0 as? ConnectionStatusUpdated }) {
            guard filter == nil || filter?($0) == true else { return }
            callback($0)
        }
    }
}
