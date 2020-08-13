//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// The base class for all controllers. Not meant to be used directly.
public class Controller {
    /// Describes the possible states of Controller
    public enum State: Equatable {
        /// The controller is inactive. Call `startUpdating` to start listening for changes.
        case inactive
        /// The controllers already fetched local data if any. Remote data fetch is in progress.
        case localDataFetched
        /// The controller fetched remote data.
        case remoteDataFetched
        /// The controller failed to fetch remote data.
        case remoteDataFetchFailed(ClientError)
    }
    
    /// The current state of the Controller.
    public internal(set) var state: State = .inactive {
        didSet {
            callback {
                self.stateDelegate?.controller(self, didChangeState: self.state)
            }
        }
    }

    /// Delegate for getting updates on `state` changes.
    internal weak var stateDelegate: ControllerStateDelegate?
    
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

/// A delegate protocol some Controllers use to propane the information about controller `state` changes. You can use it to let
/// users know a certain activity is happening in the background, i.e. using a non-blocking activity indicator.
public protocol ControllerStateDelegate: AnyObject {
    func controller(_ controller: Controller, didChangeState state: Controller.State)
}

/// Default implementation of `ControllerStateDelegate` method.
public extension ControllerStateDelegate {
    func controller(_ controller: Controller, didChangeState state: Controller.State) {}
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
