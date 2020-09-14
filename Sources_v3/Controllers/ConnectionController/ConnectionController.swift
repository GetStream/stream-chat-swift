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
    public weak var delegate: ConnectionControllerDelegate? {
        get { multicastDelegate.mainDelegate?.wrappedDelegate }
        set {
            if let newValue = newValue {
                multicastDelegate.mainDelegate = .init(newValue)
            } else {
                multicastDelegate.mainDelegate = nil
            }
        }
    }
    
    /// A callback queue in which the delegate will be called.
    public let callbackQueue: DispatchQueue?
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    @available(iOS 13, *)
    lazy var basePublisher: BasePublisher = .init(controller: self)
    
    /// A multicast delegate.
    var multicastDelegate = MulticastDelegate<ConnectionControllerWeakDelegate>() // swiftlint:disable:this weak_delegate
    
    /// The connection event observer for the connection status updates.
    private lazy var connectionEventObserver: ConnectionEventObserver = {
        .init(notificationCenter: client.webSocketClient.eventNotificationCenter) { [weak self] in
            guard let self = self else { return }
            let connectionStatus = $0.connectionStatus
            
            func notify() {
                self.multicastDelegate.invoke {
                    $0.wrappedDelegate?.controller(self, didUpdateConnectionStatus: connectionStatus)
                }
            }
            
            if let callbackQueue = self.callbackQueue {
                callbackQueue.async(execute: notify)
            } else {
                notify()
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
        super.init(notificationCenter: notificationCenter, transform: { $0 as? ConnectionStatusUpdated }) {
            guard filter == nil || filter?($0) == true else { return }
            callback($0)
        }
    }
}

/// A wrapper over `ConnectionControllerDelegate` for `MulticastDelegate` to make it weak.
struct ConnectionControllerWeakDelegate {
    weak var wrappedDelegate: ConnectionControllerDelegate?
    
    init(_ delegate: ConnectionControllerDelegate) {
        wrappedDelegate = delegate
    }
}
