//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import UIKit

@available(iOS 13, *)
extension _ChatConnectionController {
    /// A publisher emitting a new value every time the connection status changes.
    public var connectionStatusPublisher: AnyPublisher<ConnectionStatus, Never> {
        basePublishers.connectionStatus.keepAlive(self)
    }

    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapper controller
        unowned let controller: _ChatConnectionController
        
        /// A backing subject for `connectionStatusPublisher`.
        let connectionStatus: CurrentValueSubject<ConnectionStatus, Never>
                
        init(controller: _ChatConnectionController<ExtraData>) {
            self.controller = controller
            connectionStatus = .init(controller.connectionStatus)
            
            controller.multicastDelegate.additionalDelegates.append(AnyChatConnectionControllerDelegate(self))
        }
    }
}

@available(iOS 13, *)
extension _ChatConnectionController.BasePublishers: _ChatConnectionControllerDelegate {
    func connectionController(
        _ controller: _ChatConnectionController<ExtraData>,
        didUpdateConnectionStatus status: ConnectionStatus
    ) {
        connectionStatus.send(status)
    }
}
