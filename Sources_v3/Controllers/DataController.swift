//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// The base class for controllers which represent and control a data entity. Not meant to be used directly.
public class DataController: Controller {
    /// Describes the possible states of `DataController`
    public enum State: Equatable {
        /// The controller is created but no data fetched.
        case initialized
        /// The controllers already fetched local data if any.
        case localDataFetched
        /// The controller failed to fetch local data.
        case localDataFetchFailed(ClientError)
        /// The controller fetched remote data.
        case remoteDataFetched
        /// The controller failed to fetch remote data.
        case remoteDataFetchFailed(ClientError)
    }
    
    /// The current state of the controller.
    public internal(set) var state: State = .initialized {
        didSet {
            callback {
                self.stateMulticastDelegate.invoke { $0.controller(self, didChangeState: self.state) }
            }
        }
    }

    /// The queue which is used to perform callback calls. The default value is `.main`.
    public var callbackQueue: DispatchQueue = .main
    
    /// The delegate use for controller state update callbacks.
    // swiftlint:disable:next weak_delegate
    internal var stateMulticastDelegate: MulticastDelegate<DataControllerStateDelegate> = .init()
}

/// A delegate protocol some Controllers use to propagate the information about controller `state` changes. You can use it to let
/// users know a certain activity is happening in the background, i.e. using a non-blocking activity indicator.
public protocol DataControllerStateDelegate: AnyObject {
    /// Called when the observed controller changed it's state.
    ///
    /// - Parameters:
    ///   - controller: The controller the change is related to.
    ///   - state: The new state of the controller.
    func controller(_ controller: DataController, didChangeState state: DataController.State)
}

/// Default implementation of `DataControllerStateDelegate` method.
public extension DataControllerStateDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {}
}

/// A helper protocol allowing calling delegate using existing `callback` method.
protocol DelegateCallable {
    associatedtype Delegate
    func callback(_ action: @escaping () -> Void)
    
    /// The multicast delegate wrapper for all delegates of the controller
    var multicastDelegate: MulticastDelegate<Delegate> { get }
}

extension DelegateCallable {
    /// A helper function to ensure the delegate callback is performed using the `callback` method.
    func delegateCallback(_ callback: @escaping (Delegate) -> Void) {
        self.callback {
            self.multicastDelegate.invoke(callback)
        }
    }
}
