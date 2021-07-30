//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension ChatClient {
    /// Creates a new `ChatConnectionController` instance.
    ///
    /// - Returns: A new instance of `ChatConnectionController`.
    ///
    func connectionController() -> ChatConnectionController {
        .init(client: self)
    }
}

/// `ChatConnectionController` is a controller class which allows to explicitly
/// connect/disconnect the `ChatClient` and observe connection events.
public class ChatConnectionController: Controller, DelegateCallable, DataStoreProvider {
    public var callbackQueue: DispatchQueue = .main
    
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient
    
    private let environment: Environment
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    @available(iOS 13, *)
    lazy var basePublishers: BasePublishers = .init(controller: self)
    
    /// The current connection status of the client.
    ///
    /// To observe changes of the connection status, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    ///
    public var connectionStatus: ConnectionStatus {
        client.connectionStatus
    }
    
    /// The connection event observer for the connection status updates.
    private var connectionEventObserver: ConnectionEventObserver?

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<AnyChatConnectionControllerDelegate> = .init()

    private lazy var chatClientUpdater = environment.chatClientUpdaterBuilder(client)

    /// Creates a new `ChatConnectionControllerGeneric`.
    ///
    /// - Parameters:
    ///   - client: The `Client` instance this controller belongs to.
    ///   - environment: The source of internal dependencies
    ///
    init(client: ChatClient, environment: Environment = .init()) {
        self.client = client
        self.environment = environment
        connectionEventObserver = setupObserver()
    }
    
    private func setupObserver() -> ConnectionEventObserver? {
        guard let webSocketClient = client.webSocketClient else { return nil }
        let observer = ConnectionEventObserver(
            notificationCenter: webSocketClient.eventNotificationCenter
        ) { [unowned self] status in
            self.delegateCallback {
                $0.connectionController(self, didUpdateConnectionStatus: status.connectionStatus)
            }
        }
        return observer
    }
}

public extension ChatConnectionController {
    /// Connects the chat client the controller represents to the chat servers.
    ///
    /// When the connection is established, `ChatClient` starts receiving chat updates.
    ///
    /// - Parameter completion: Called when the connection is established. If the connection fails, the completion is
    /// called with an error.
    ///
    func connect(completion: ((Error?) -> Void)? = nil) {
        chatClientUpdater.connect { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Disconnects the chat client the controller represents from the chat servers.
    /// No further updates from the servers are received.
    func disconnect() {
        chatClientUpdater.disconnect()
    }
}

// MARK: - Environment

extension ChatConnectionController {
    struct Environment {
        var chatClientUpdaterBuilder = ChatClientUpdater.init
    }
}

// MARK: - Delegates

/// `ChatConnectionController` uses this protocol to communicate changes to its delegate.
///
/// This protocol can be used only when no custom extra data are specified.
/// If you're using custom extra data types, please use `_ChatConnectionControllerDelegate` instead.
///
public protocol ChatConnectionControllerDelegate: AnyObject {
    /// The controller observed a change in connection status.
    func connectionController(_ controller: ChatConnectionController, didUpdateConnectionStatus status: ConnectionStatus)
}

public extension ChatConnectionControllerDelegate {
    func connectionController(_ controller: ChatConnectionController, didUpdateConnectionStatus status: ConnectionStatus) {}
}

final class AnyChatConnectionControllerDelegate: ChatConnectionControllerDelegate {
    weak var wrappedDelegate: AnyObject?
    
    private var _controllerDidChangeConnectionStatus: (
        ChatConnectionController,
        ConnectionStatus
    ) -> Void
    
    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeConnectionStatus: @escaping (
            ChatConnectionController,
            ConnectionStatus
        ) -> Void
    ) {
        self.wrappedDelegate = wrappedDelegate
        _controllerDidChangeConnectionStatus = controllerDidChangeConnectionStatus
    }
    
    func connectionController(
        _ controller: ChatConnectionController,
        didUpdateConnectionStatus status: ConnectionStatus
    ) {
        _controllerDidChangeConnectionStatus(controller, status)
    }
}

extension AnyChatConnectionControllerDelegate {
    convenience init<Delegate: ChatConnectionControllerDelegate>(_ delegate: Delegate) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeConnectionStatus: { [weak delegate] in
                delegate?.connectionController($0, didUpdateConnectionStatus: $1)
            }
        )
    }
}

extension AnyChatConnectionControllerDelegate {
    convenience init(_ delegate: ChatConnectionControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeConnectionStatus: { [weak delegate] in
                delegate?.connectionController($0, didUpdateConnectionStatus: $1)
            }
        )
    }
}
 
public extension ChatConnectionController {
    /// Sets the provided object as a delegate of this controller.
    ///
    /// - Note: If you don't use custom extra data types, you can set the delegate directly using `controller.delegate = self`.
    /// Due to the current limits of Swift and the way it handles protocols with associated types, it's required to use this
    /// method to set the delegate, if you're using custom extra data types.
    ///
    /// - Parameter delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object
    /// alive if you want keep receiving updates.
    func setDelegate<Delegate: ChatConnectionControllerDelegate>(_ delegate: Delegate?) {
        multicastDelegate.mainDelegate = delegate.flatMap(AnyChatConnectionControllerDelegate.init)
    }
}

public extension ChatConnectionController {
    /// Set the delegate of `ChatConnectionController` to observe the changes in the system.
    ///
    /// - Note: The delegate can be set directly only if you're **not** using custom extra data types. Due to the current
    /// limits of Swift and the way it handles protocols with associated types, it's required to use `setDelegate` method
    /// instead to set the delegate, if you're using custom extra data types.
    var delegate: ChatConnectionControllerDelegate? {
        get { multicastDelegate.mainDelegate?.wrappedDelegate as? ChatConnectionControllerDelegate }
        set { multicastDelegate.mainDelegate = AnyChatConnectionControllerDelegate(newValue) }
    }
}

/// A connection event observer to handle `ConnectionStatusUpdated` events.
private class ConnectionEventObserver: EventObserver {
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
