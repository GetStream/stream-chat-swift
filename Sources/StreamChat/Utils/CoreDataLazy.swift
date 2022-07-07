//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
    
    /// The persistent store identifier by the time this wrapper is initialized.
    /// This is used to detect when there are lingering models in the memory, which will cause a crash when tried to materialize.
    var persistentStoreIdentifier: String?
    
    var wrappedValue: T {
        var returnValue: T!

        // We need to make the changes inside the `mutate` block to ensure the wrapper is thread-safe.
        __cached.mutate { value in
            
            if let value = value {
                returnValue = value
                return
            }

            let perform = {
                log.assert(self.computeValue != nil, "You must set the `computeValue` closure before accessing the cached value.")
                returnValue = self.computeValue()
            }
            
            if let context = context {
                guard persistentStoreIdentifier == context.persistentStoreCoordinator?.persistentStores.first?.identifier else {
                    let message = """
                    Persistent store identifier changed. This means the persistent store was reloaded, but a reference to a model was kept in memory.
                    This can happen if a snapshot of data (ChatMessage, ChatUser, ChatChannel) was kept in memory after Database is wiped (for example, in the event of logging in with a new user).
                    If you're sure there are no references to models from another session, please report this stack trace to Stream iOS Team.
                    """
                    log.error(message)
                    fatalError(String(describing: message))
                }
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
            persistentStoreIdentifier = context?.persistentStoreCoordinator?.persistentStores.first?.identifier
            if !StreamRuntimeCheck._isLazyMappingEnabled {
                _cached = computeValue()
            } else {
                _cached = nil
            }
        }
    }
    
    /// The previously evaluated value. `nil` if the wrapper hasn't been evaluated yet.
    @Atomic private var _cached: T?
}
