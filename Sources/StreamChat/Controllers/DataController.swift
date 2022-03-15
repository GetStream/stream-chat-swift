//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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

    /// Determines whether the controller can be recovered. A failure fetching remote data can mean that we failed to fetch the data that is present on the server, or
    /// that we failed to synchronize a locally created channel
    var canBeRecovered: Bool {
        switch state {
        case .remoteDataFetched, .remoteDataFetchFailed:
            return true
        case .initialized, .localDataFetched, .localDataFetchFailed:
            return false
        }
    }
    
    /// Synchronize local data with remote.
    ///
    /// **Asynchronously** fetches the latest version of the data from the servers. Once the remote fetch is completed,
    /// the completion block is called. If the updated data differ from the locally cached ones, the controller uses the
    /// callback methods (delegate, `Combine` publishers, etc.) to inform about the changes.
    ///
    /// - Parameter completion: Called when the controller has finished fetching remote data. If the data fetching fails,
    /// the `error` variable contains more details about the problem.
    ///
    public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
        fatalError("`synchronize` method must be overriden by the subclass.")
    }

    /// The queue which is used to perform callback calls. The default value is `.main`.
    public var callbackQueue: DispatchQueue = .main
    
    /// The delegate use for controller state update callbacks.
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
