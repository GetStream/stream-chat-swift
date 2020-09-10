//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 13, *)
extension ConnectionControllerGeneric {
    /// A wrapper object that exposes the controller connection status in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }
    
    /// A wrapper object for `ConnectionController` type which makes it possible to use the controller comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public unowned let controller: ConnectionControllerGeneric
        
        /// The connection status.
        @Published public private(set) var connectionStatus: ConnectionStatus
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: ConnectionControllerGeneric<ExtraData>) {
            self.controller = controller
            connectionStatus = controller.connectionStatus
            controller.multicastDelegate.additionalDelegates.append(.init(self))
        }
    }
}

@available(iOS 13, *)
extension ConnectionControllerGeneric.ObservableObject: ConnectionControllerDelegate {
    public func controller<ExtraData: ExtraDataTypes>(
        _ controller: ConnectionControllerGeneric<ExtraData>,
        didUpdateConnectionStatus status: ConnectionStatus
    ) {
        connectionStatus = status
    }
}
