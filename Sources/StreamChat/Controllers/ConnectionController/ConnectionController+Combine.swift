//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

@available(iOS 13, *)
extension ChatConnectionController {
    /// A publisher emitting a new value every time the connection status changes.
    public var connectionStatusPublisher: AnyPublisher<ConnectionStatus, Never> {
        basePublishers.connectionStatus.keepAlive(self)
    }

    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapper controller
        unowned let controller: ChatConnectionController
        
        /// A backing subject for `connectionStatusPublisher`.
        let connectionStatus: CurrentValueSubject<ConnectionStatus, Never>
                
        init(controller: ChatConnectionController) {
            self.controller = controller
            connectionStatus = .init(controller.connectionStatus)
            
            controller.multicastDelegate.add(additionalDelegate: self)
        }
    }
}

@available(iOS 13, *)
extension ChatConnectionController.BasePublishers: ChatConnectionControllerDelegate {
    func connectionController(
        _ controller: ChatConnectionController,
        didUpdateConnectionStatus status: ConnectionStatus
    ) {
        connectionStatus.send(status)
    }
}
