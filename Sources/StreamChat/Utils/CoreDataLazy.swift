//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// Makes it possible to lazily evaluate properties of `NSManagedObject`s.
///
/// Works like a "classic" lazy wrapper. The only different is that the `computeValue` closure is evaluated on the queue
/// of the provided `NSManagedObjectContext`.
///
@propertyWrapper
class CoreDataLazy<T> {
    /// When the cached value is reset, this closure is used to lazily get a new value which is then cached again.
    var computeValue: (() -> T)!
    
    /// The context on whose queue is the `computeValue` closure evaluated.
    weak var context: NSManagedObjectContext?
    
    var wrappedValue: T {
        var returnValue: T!

        // We need to make the changes inside the `mutate` block to ensure the wrapper is thread-safe.
        __cached.mutate { [weak self] value in
            
            if let value = value {
                returnValue = value
                return
            }

            let perform = {
                guard let computeValue = self?.computeValue else {
                    log.assertionFailure(
                        "You must set the `computeValue` closure before accessing the cached value."
                    )
                    return
                }
                returnValue = computeValue()
            }
            
            if let context = context {
                context.performAndWait { perform() }
            } else {
                // This is a fallback for cases like tests, mocks, and other cases where it's known `computeValue` doesn't need to
                // evaluated using `context.performAndWait {}`.
                perform()
            }
            
            value = returnValue
        }
        
        return returnValue
    }
    
    /// A tuple container the closure which evaluates the lazy value, and the managed object context on which the closure should be performed.
    var projectedValue: (() -> T, NSManagedObjectContext?) {
        get {
            log.assert(computeValue != nil, "You must set the `computeValue` closure before accessing it.")
            return (computeValue, context)
        }
        set {
            computeValue = newValue.0
            context = newValue.1
        }
    }
    
    /// The previously evaluated value. `nil` if the wrapper hasn't been evaluated yet.
    @Atomic private var _cached: T?
}
