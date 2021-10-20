//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension EventsController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }
    
    /// A wrapper object for `UserListController` type which makes it possible to use the controller comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: EventsController
        
        /// The last observed event.
        @Published public private(set) var mostRecentEvent: Event?
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: EventsController) {
            self.controller = controller
            controller.multicastDelegate.add(additionalDelegate: self)
        }
    }
}

@available(iOS 13, *)
extension EventsController.ObservableObject: EventsControllerDelegate {
    public func eventsController(
        _ controller: EventsController,
        didReceiveEvent event: Event
    ) {
        mostRecentEvent = event
    }
}
