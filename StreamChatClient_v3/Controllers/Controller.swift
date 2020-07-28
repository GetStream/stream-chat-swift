//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// The base class for all controllers. Not meant to be used directly.
public class Controller {
    /// The queue which is used to perform callback calls. The default value is `.main`.
    public var callbackQueue: DispatchQueue = .main
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

/// A helper protocol allowing calling delegate on a given dispatch queue.
protocol DelegateCallbable {
    associatedtype Delegate
    var anyDelegate: Delegate { get }
}

extension DelegateCallbable where Self: Controller {
    func delegateCallback(_ callback: @escaping (Delegate) -> Void) {
        callbackQueue.async {
            callback(self.anyDelegate)
        }
    }
}
