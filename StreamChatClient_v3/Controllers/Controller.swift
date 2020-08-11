//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// The base class for all controllers. Not meant to be used directly.
public class Controller {
    /// Describes the possible states of Controller
    public enum State: Equatable {
        /// The controller is idle. Call `startUpdating` to start listening for changes.
        case idle
        
        /// The controller is active and is listening to changes.
        case active
    }
    
    /// The current state of the Controller.
    public internal(set) var state: State = .idle
    
    /// The queue which is used to perform callback calls. The default value is `.main`.
    public var callbackQueue: DispatchQueue = .main
}

extension Controller {
    /// A helper function to ensure the callback is performed on the callback queue.
    func callback(_ action: @escaping () -> Void) {
        if callbackQueue == .main, Thread.current.isMainThread {
            // Perform the action on the main queue synchronously
            action()
        } else {
            callbackQueue.async {
                action()
            }
        }
    }
}

/// A delegate protocol some Controllers use to propane the information about remote data fetching. You can use it to let
/// users know a certain activity is happening in the background, i.e. using a non-blocking activity indicator.
public protocol ControllerRemoteActivityDelegate: AnyObject {
    func controllerWillStartFetchingRemoteData(_ controller: Controller)
    func controllerDidStopFetchingRemoteData(_ controller: Controller, withError error: Error?)
}

/// Default implementation of `ControllerRemoteActivityDelegate` methods.
public extension ControllerRemoteActivityDelegate {
    /// The controller will make a network request to update the local data.
    func controllerWillStartFetchingRemoteData(_ controller: Controller) {}
    
    /// The controller did finished fetching the remote data. If the request failed, the error is reported.
    func controllerDidStopFetchingRemoteData(_ controller: Controller, withError error: Error?) {}
}

/// A helper protocol allowing calling delegate using existing `callback` method.
protocol DelegateCallable {
    associatedtype Delegate
    func callback(_ action: @escaping () -> Void)
    var anyDelegate: Delegate { get }
}

extension DelegateCallable {
    /// A helper function to ensure the delegate callback is performed using the `callback` method.
    func delegateCallback(_ callback: @escaping (Delegate) -> Void) {
        self.callback {
            callback(self.anyDelegate)
        }
    }
}
