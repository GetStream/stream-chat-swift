//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension Client {
    /// Creates a new `CurrentUserControllerGeneric`
    /// - Returns: A new instance of `ChannelController`.
    func currentUserController() -> CurrentUserControllerGeneric<ExtraData> {
        .init(client: self, environment: .init())
    }
}

/// A convenience typealias for `CurrentUserControllerGeneric` with `DefaultDataTypes`
public typealias CurrentUserController = CurrentUserControllerGeneric<DefaultDataTypes>

/// `CurrentUserControllerGeneric` allows to observer current user updates
public class CurrentUserControllerGeneric<ExtraData: ExtraDataTypes>: Controller, DelegateCallable, DataStoreProvider {
    /// The `ChatClient` instance this controller belongs to.
    public let client: Client<ExtraData>
    
    private let environment: Environment
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    @available(iOS 13, *)
    lazy var basePublishers: BasePublishers = .init(controller: self)

    /// Used for observing the curren-user changes in a database.
    private lazy var currentUserObserver = createUserObserver()
        .onChange { [unowned self] change in
            self.delegateCallback {
                $0.currentUserController(self, didChangeCurrentUser: change)
            }
        }
        .onFieldChange(\.unreadCount) { [unowned self] change in
            self.delegateCallback {
                $0.currentUserController(self, didChangeCurrentUserUnreadCount: change.unreadCount)
            }
        }

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<AnyCurrentUserControllerDelegate<ExtraData>> = .init() {
        didSet {
            stateMulticastDelegate.mainDelegate = multicastDelegate.mainDelegate
            stateMulticastDelegate.additionalDelegates = multicastDelegate.additionalDelegates
        }
    }
    
    /// The currently logged-in user.
    /// Always returns `nil` if `startUpdating` was not called
    /// To observe the updates of this value, set your class as a delegate of this controller and call `startUpdating`.
    public var currentUser: CurrentUserModel<ExtraData.User>? {
        guard state != .inactive else {
            log.warning("Accessing `currentUser` fields before calling `startUpdating()` always results in `nil`.")
            return nil
        }

        return currentUserObserver.item
    }

    /// The unread messages and channels count for the current user.
    /// Always returns `noUnread` if `startUpdating` was not called.
    /// To observe the updates of this value, set your class as a delegate of this controller and call `startUpdating`.
    public var unreadCount: UnreadCount {
        currentUser?.unreadCount ?? .noUnread
    }

    /// Creates a new `CurrentUserControllerGeneric`.
    /// - Parameters:
    ///   - client: The `Client` instance this controller belongs to.
    ///   - environment: The source of internal dependencies
    init(client: Client<ExtraData>, environment: Environment = .init()) {
        self.client = client
        self.environment = environment
    }
    
    /// Starts updating the results.
    ///
    /// It **synchronously** loads the data for the referenced objects from the local cache.
    /// The `currentUser` and `unreadCount` properties are immediately available once this method returns.
    /// Any further changes to the data are communicated using `delegate`.
    ///
    /// - Parameter completion: Called when the controller has finished fetching data from a database.
    /// If the data fetching fails, the `error` variable contains more details about the problem.
    public func startUpdating(_ completion: ((Error?) -> Void)? = nil) {
        do {
            try currentUserObserver.startObserving()
        } catch {
            callback { completion?(ClientError.FetchFailed()) }
            return
        }
        
        state = .localDataFetched

        callback { completion?(nil) }
    }
}

// MARK: - Environment

extension CurrentUserControllerGeneric {
    struct Environment {
        var currentUserObserverBuilder: (
            _ context: NSManagedObjectContext,
            _ fetchRequest: NSFetchRequest<CurrentUserDTO>,
            _ itemCreator: @escaping (CurrentUserDTO) -> CurrentUserModel<ExtraData.User>,
            _ fetchedResultsControllerType: NSFetchedResultsController<CurrentUserDTO>.Type
        ) -> EntityDatabaseObserver<CurrentUserModel<ExtraData.User>, CurrentUserDTO> = EntityDatabaseObserver.init
    }
}

// MARK: - Private

private extension EntityChange where Item == UnreadCount {
    var unreadCount: UnreadCount {
        switch self {
        case let .create(count):
            return count
        case let .update(count):
            return count
        case .remove:
            return .noUnread
        }
    }
}

private extension CurrentUserControllerGeneric {
    func createUserObserver() -> EntityDatabaseObserver<CurrentUserModel<ExtraData.User>, CurrentUserDTO> {
        environment.currentUserObserverBuilder(
            client.databaseContainer.viewContext,
            CurrentUserDTO.defaultFetchRequest,
            { $0.asModel() }, // swiftlint:disable:this opening_brace
            NSFetchedResultsController<CurrentUserDTO>.self
        )
    }
}

// MARK: - Delegates

/// `CurrentUserController` uses this protocol to communicate changes to its delegate.
///
/// This protocol can be used only when no custom extra data are specified.
/// If you're using custom extra data types, please use `CurrentUserControllerDelegateGeneric` instead.
public protocol CurrentUserControllerDelegate: ControllerStateDelegate {
    /// The controller observed a change in the `UnreadCount`.
    func currentUserController(_ controller: CurrentUserController, didChangeCurrentUserUnreadCount: UnreadCount)
    
    /// The controller observed a change in the `CurrentUser` entity.
    func currentUserController(_ controller: CurrentUserController, didChangeCurrentUser: EntityChange<CurrentUser>)
}

public extension CurrentUserControllerDelegate {
    func currentUserController(_ controller: CurrentUserController, didChangeCurrentUserUnreadCount: UnreadCount) {}
    
    func currentUserController(_ controller: CurrentUserController, didChangeCurrentUser: EntityChange<CurrentUser>) {}
}

/// `CurrentUserControllerGeneric` uses this protocol to communicate changes to its delegate.
///
/// If you're **not** using custom extra data types, you can use a convenience version of this protocol
/// named `CurrentUserControllerDelegate`, which hides the generic types, and make the usage easier.
public protocol CurrentUserControllerDelegateGeneric: ControllerStateDelegate {
    associatedtype ExtraData: ExtraDataTypes
    
    /// The controller observed a change in the `UnreadCount`.
    func currentUserController(_ controller: CurrentUserControllerGeneric<ExtraData>, didChangeCurrentUserUnreadCount: UnreadCount)
    
    /// The controller observed a change in the `CurrentUser` entity.
    func currentUserController(
        _ controller: CurrentUserControllerGeneric<ExtraData>,
        didChangeCurrentUser: EntityChange<CurrentUserModel<ExtraData.User>>
    )
}

public extension CurrentUserControllerDelegateGeneric {
    func currentUserController(
        _ controller: CurrentUserControllerGeneric<ExtraData>,
        didChangeCurrentUserUnreadCount: UnreadCount
    ) {}
    
    func currentUserController(
        _ controller: CurrentUserControllerGeneric<ExtraData>,
        didChangeCurrentUser: EntityChange<CurrentUserModel<ExtraData.User>>
    ) {}
}

final class AnyCurrentUserControllerDelegate<ExtraData: ExtraDataTypes>: CurrentUserControllerDelegateGeneric {
    weak var wrappedDelegate: AnyObject?
    
    private var _controllerDidChangeState: (
        Controller,
        Controller.State
    ) -> Void
    
    private var _controllerDidChangeCurrentUserUnreadCount: (
        CurrentUserControllerGeneric<ExtraData>,
        UnreadCount
    ) -> Void
    
    private var _controllerDidChangeCurrentUser: (
        CurrentUserControllerGeneric<ExtraData>,
        EntityChange<CurrentUserModel<ExtraData.User>>
    ) -> Void

    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeState: @escaping (
            Controller,
            Controller.State
        ) -> Void,
        controllerDidChangeCurrentUserUnreadCount: @escaping (
            CurrentUserControllerGeneric<ExtraData>,
            UnreadCount
        ) -> Void,
        controllerDidChangeCurrentUser: @escaping (
            CurrentUserControllerGeneric<ExtraData>,
            EntityChange<CurrentUserModel<ExtraData.User>>
        ) -> Void
    ) {
        self.wrappedDelegate = wrappedDelegate
        _controllerDidChangeCurrentUserUnreadCount = controllerDidChangeCurrentUserUnreadCount
        _controllerDidChangeState = controllerDidChangeState
        _controllerDidChangeCurrentUser = controllerDidChangeCurrentUser
    }

    func controller(_ controller: Controller, didChangeState state: Controller.State) {
        _controllerDidChangeState(controller, state)
    }

    func currentUserController(
        _ controller: CurrentUserControllerGeneric<ExtraData>,
        didChangeCurrentUserUnreadCount unreadCount: UnreadCount
    ) {
        _controllerDidChangeCurrentUserUnreadCount(controller, unreadCount)
    }
    
    func currentUserController(
        _ controller: CurrentUserControllerGeneric<ExtraData>,
        didChangeCurrentUser user: EntityChange<CurrentUserModel<ExtraData.User>>
    ) {
        _controllerDidChangeCurrentUser(controller, user)
    }
}

extension AnyCurrentUserControllerDelegate {
    convenience init<Delegate: CurrentUserControllerDelegateGeneric>(_ delegate: Delegate) where Delegate.ExtraData == ExtraData {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidChangeCurrentUserUnreadCount: { [weak delegate] in
                delegate?.currentUserController($0, didChangeCurrentUserUnreadCount: $1)
            },
            controllerDidChangeCurrentUser: { [weak delegate] in
                delegate?.currentUserController($0, didChangeCurrentUser: $1)
            }
        )
    }
}

extension AnyCurrentUserControllerDelegate where ExtraData == DefaultDataTypes {
    convenience init(_ delegate: CurrentUserControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidChangeCurrentUserUnreadCount: { [weak delegate] in
                delegate?.currentUserController($0, didChangeCurrentUserUnreadCount: $1)
            },
            controllerDidChangeCurrentUser: { [weak delegate] in
                delegate?.currentUserController($0, didChangeCurrentUser: $1)
            }
        )
    }
}
 
public extension CurrentUserControllerGeneric {
    /// Sets the provided object as a delegate of this controller.
    ///
    /// - Note: If you don't use custom extra data types, you can set the delegate directly using `controller.delegate = self`.
    /// Due to the current limits of Swift and the way it handles protocols with associated types, it's required to use this
    /// method to set the delegate, if you're using custom extra data types.
    ///
    /// - Parameter delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object
    /// alive if you want keep receiving updates.
    func setDelegate<Delegate: CurrentUserControllerDelegateGeneric>(_ delegate: Delegate?) where Delegate.ExtraData == ExtraData {
        multicastDelegate.mainDelegate = delegate.flatMap(AnyCurrentUserControllerDelegate.init)
    }
}

public extension CurrentUserController {
    /// Set the delegate of `CurrentUserController` to observe the changes in the system.
    ///
    /// - Note: The delegate can be set directly only if you're **not** using custom extra data types. Due to the current
    /// limits of Swift and the way it handles protocols with associated types, it's required to use `setDelegate` method
    /// instead to set the delegate, if you're using custom extra data types.
    var delegate: CurrentUserControllerDelegate? {
        set { multicastDelegate.mainDelegate = AnyCurrentUserControllerDelegate(newValue) }
        get { multicastDelegate.mainDelegate?.wrappedDelegate as? CurrentUserControllerDelegate }
    }
}
