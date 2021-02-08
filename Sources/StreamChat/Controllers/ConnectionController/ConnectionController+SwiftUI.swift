//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension _ChatConnectionController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }
    
    /// A wrapper object for `CurrentUserController` type which makes it possible to use the controller comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: _ChatConnectionController
        
        /// The connection status.
        @Published public private(set) var connectionStatus: ConnectionStatus
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: _ChatConnectionController<ExtraData>) {
            self.controller = controller
            connectionStatus = controller.connectionStatus
            
            controller.multicastDelegate.additionalDelegates.append(AnyChatConnectionControllerDelegate(self))
        }
    }
}

@available(iOS 13, *)
extension _ChatConnectionController.ObservableObject: _ChatConnectionControllerDelegate {
    public func connectionController(
        _ controller: _ChatConnectionController<ExtraData>,
        didUpdateConnectionStatus status: ConnectionStatus
    ) {
        connectionStatus = status
    }
}
