//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
    var multicastDelegate: MulticastDelegate<ChatConnectionControllerDelegate> = .init()

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
        ) { [weak self] status in
            self?.delegateCallback { [weak self] in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }
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
        chatClientUpdater.disconnect(source: .userInitiated) {
            log.info("The `ChatClient` has been disconnected.", subsystems: .webSocket)
        }
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
public protocol ChatConnectionControllerDelegate: AnyObject {
    /// The controller observed a change in connection status.
    func connectionController(_ controller: ChatConnectionController, didUpdateConnectionStatus status: ConnectionStatus)
}

public extension ChatConnectionControllerDelegate {
    func connectionController(_ controller: ChatConnectionController, didUpdateConnectionStatus status: ConnectionStatus) {}
}

public extension ChatConnectionController {
    /// Set the delegate of `ChatConnectionController` to observe the changes in the system.
    var delegate: ChatConnectionControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
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
