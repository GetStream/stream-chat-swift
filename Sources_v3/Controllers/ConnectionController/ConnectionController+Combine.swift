//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Combine

@available(iOS 13, *)
extension ConnectionControllerGeneric {
    /// A publisher emitting a new value every time the connection status changes.
    public var connectionStatusPublisher: AnyPublisher<ConnectionStatus, Never> {
        basePublisher.connectionStatus.keepAlive(self)
    }
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublisher {
        /// The wrapper controller.
        unowned let controller: ConnectionControllerGeneric
        
        /// A backing subject for `connectionStatusPublisher`.
        let connectionStatus: CurrentValueSubject<ConnectionStatus, Never>
        
        init(controller: ConnectionControllerGeneric<ExtraData>) {
            self.controller = controller
            connectionStatus = .init(controller.connectionStatus)
            controller.multicastDelegate.additionalDelegates.append(.init(self))
        }
    }
}

@available(iOS 13, *)
extension ConnectionControllerGeneric.BasePublisher: ConnectionControllerDelegate {
    func controller<ExtraData: ExtraDataTypes>(
        _ controller: ConnectionControllerGeneric<ExtraData>,
        didUpdateConnectionStatus status: ConnectionStatus
    ) {
        connectionStatus.send(status)
    }
}
