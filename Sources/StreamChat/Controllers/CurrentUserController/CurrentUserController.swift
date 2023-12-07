//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension ChatClient {
    /// Creates a new `CurrentUserController` instance.
    ///
    /// - Returns: A new instance of `CurrentChatUserController`.
    ///
    func currentUserController() -> CurrentChatUserController {
        .init(client: self)
    }
}

/// `CurrentChatUserController` is a controller class which allows observing and mutating the currently logged-in
/// user of `ChatClient`.
public class CurrentChatUserController: DataController, DelegateCallable, DataStoreProvider {
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    private let environment: Environment

    var _basePublishers: Any?
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    @available(iOS 13, *)
    var basePublishers: BasePublishers {
        if let value = _basePublishers as? BasePublishers {
            return value
        }
        _basePublishers = BasePublishers(controller: self)
        return _basePublishers as? BasePublishers ?? .init(controller: self)
    }

    /// Used for observing the current user changes in a database.
    private lazy var currentUserObserver = createUserObserver()
        .onChange { [weak self] change in
            self?.delegateCallback { [weak self] in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }
                $0.currentUserController(self, didChangeCurrentUser: change)
            }
        }
        .onFieldChange(\.unreadCount) { [weak self] change in
            self?.delegateCallback { [weak self] in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }
                $0.currentUserController(self, didChangeCurrentUserUnreadCount: change.unreadCount)
            }
        }

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<CurrentChatUserControllerDelegate> = .init()

    /// The currently logged-in user. `nil` if the connection hasn't been fully established yet, or the connection
    /// wasn't successful.
    /// Having a non-nil currentUser does not mean the user is authenticated. Make sure to call `connect()` before performing any API call.
    public var currentUser: CurrentChatUser? {
        startObservingIfNeeded()
        return currentUserObserver.item
    }

    /// The unread messages and channels count for the current user.
    ///
    /// Returns `noUnread` if `currentUser` doesn't exist yet.
    ///
    public var unreadCount: UnreadCount {
        currentUser?.unreadCount ?? .noUnread
    }

    /// The worker used to update the current user.
    private lazy var currentUserUpdater = environment.currentUserUpdaterBuilder(
        client.databaseContainer,
        client.apiClient
    )

    /// Creates a new `CurrentUserControllerGeneric`.
    ///
    /// - Parameters:
    ///   - client: The `Client` instance this controller belongs to.
    ///   - environment: The source of internal dependencies
    ///
    init(client: ChatClient, environment: Environment = .init()) {
        self.client = client
        self.environment = environment
    }

    /// Synchronize local data with remote. Waits for the client to connect but doesn’t initiate the connection itself.
    /// This is to make sure the fetched local data is up-to-date, since the current user data is updated through WebSocket events.
    ///
    /// - Parameter completion: Called when the controller has finished fetching the local data
    ///   and the client connection is established.
    override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
        startObservingIfNeeded()

        if case let .localDataFetchFailed(error) = state {
            callback { completion?(error) }
            return
        }

        // Unlike the other DataControllers, this one does not make a remote call when synchronising.
        // But we can assume that if we wait for the connection of the WebSocket, it means the local data
        // is in sync with the remote server, so we can set the state to remoteDataFetched.
        client.provideConnectionId { [weak self] result in
            var error: ClientError?
            if case .failure = result {
                error = ClientError.ConnectionNotSuccessful()
            }

            self?.state = error == nil ? .remoteDataFetched : .remoteDataFetchFailed(error!)
            self?.callback { completion?(error) }
        }
    }

    private func startObservingIfNeeded() {
        guard state == .initialized else { return }

        do {
            try currentUserObserver.startObserving()
            state = .localDataFetched
        } catch {
            log.error("""
            Observing current user failed: \(error).\n
            Accessing `currentUser` will always return `nil`, `unreadCount` with `.noUnread`
            """)
            state = .localDataFetchFailed(ClientError(with: error))
        }
    }
}

public extension CurrentChatUserController {
    /// Fetches the token from `tokenProvider` and prepares the current `ChatClient` variables
    /// for the new user.
    ///
    /// If the a token obtained from `tokenProvider` is for another user the
    /// database will be flushed.
    ///
    /// - Parameter completion: The completion to be called when the operation is completed.
    func reloadUserIfNeeded(completion: ((Error?) -> Void)? = nil) {
        client.authenticationRepository.refreshToken { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Updates the current user data.
    ///
    /// By default all data is `nil`, and it won't be updated unless a value is provided.
    ///
    /// - Parameters:
    ///   - name: Optionally provide a new name to be updated.
    ///   - imageURL: Optionally provide a new image to be updated.
    ///   - userExtraData: Optionally provide new user extra data to be updated.
    ///   - completion: Called when user is successfuly updated, or with error.
    func updateUserData(
        name: String? = nil,
        imageURL: URL? = nil,
        userExtraData: [String: RawJSON] = [:],
        completion: ((Error?) -> Void)? = nil
    ) {
        guard let currentUserId = client.currentUserId else {
            completion?(ClientError.CurrentUserDoesNotExist())
            return
        }

        currentUserUpdater.updateUserData(
            currentUserId: currentUserId,
            name: name,
            imageURL: imageURL,
            userExtraData: userExtraData
        ) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Fetches the most updated devices and syncs with the local database.
    /// - Parameter completion: Called when the devices are synced successfully, or with error.
    func synchronizeDevices(completion: ((Error?) -> Void)? = nil) {
        guard let currentUserId = client.currentUserId else {
            completion?(ClientError.CurrentUserDoesNotExist())
            return
        }

        currentUserUpdater.fetchDevices(currentUserId: currentUserId) { error in
            self.callback { completion?(error) }
        }
    }

    /// Registers the current user's device for push notifications.
    /// - Parameters:
    ///   - pushDevice: The device information required for the desired push provider.
    ///   - completion: Callback when device is successfully registered, or failed with error.
    func addDevice(_ pushDevice: PushDevice, completion: ((Error?) -> Void)? = nil) {
        guard let currentUserId = client.currentUserId else {
            completion?(ClientError.CurrentUserDoesNotExist())
            return
        }

        currentUserUpdater.addDevice(
            deviceId: pushDevice.deviceId,
            pushProvider: pushDevice.pushProvider,
            providerName: pushDevice.providerName,
            currentUserId: currentUserId
        ) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Removes a registered device from the current user.
    /// `connectUser` must be called before calling this.
    /// - Parameters:
    ///   - id: Device id to be removed. You can obtain registered devices via `currentUser.devices`.
    ///   If `currentUser.devices` is not up-to-date, please make an `synchronize` call.
    ///   - completion: Called when device is successfully deregistered, or with error.
    func removeDevice(id: DeviceId, completion: ((Error?) -> Void)? = nil) {
        guard let currentUserId = client.currentUserId else {
            completion?(ClientError.CurrentUserDoesNotExist())
            return
        }

        currentUserUpdater.removeDevice(id: id, currentUserId: currentUserId) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Marks all channels for a user as read.
    ///
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    func markAllRead(completion: ((Error?) -> Void)? = nil) {
        currentUserUpdater.markAllRead { error in
            self.callback {
                completion?(error)
            }
        }
    }
}

// MARK: - Environment

extension CurrentChatUserController {
    struct Environment {
        var currentUserObserverBuilder: (
            _ context: NSManagedObjectContext,
            _ fetchRequest: NSFetchRequest<CurrentUserDTO>,
            _ itemCreator: @escaping (CurrentUserDTO) throws -> CurrentChatUser,
            _ fetchedResultsControllerType: NSFetchedResultsController<CurrentUserDTO>.Type
        ) -> EntityDatabaseObserver<CurrentChatUser, CurrentUserDTO> = EntityDatabaseObserver.init

        var currentUserUpdaterBuilder = CurrentUserUpdater.init
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

private extension CurrentChatUserController {
    func createUserObserver() -> EntityDatabaseObserver<CurrentChatUser, CurrentUserDTO> {
        environment.currentUserObserverBuilder(
            client.databaseContainer.viewContext,
            CurrentUserDTO.defaultFetchRequest,
            { try $0.asModel() },
            NSFetchedResultsController<CurrentUserDTO>.self
        )
    }
}

// MARK: - Delegates

/// `CurrentChatUserController` uses this protocol to communicate changes to its delegate.
public protocol CurrentChatUserControllerDelegate: AnyObject {
    /// The controller observed a change in the `UnreadCount`.
    func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUserUnreadCount: UnreadCount)

    /// The controller observed a change in the `CurrentChatUser` entity.
    func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUser: EntityChange<CurrentChatUser>)
}

public extension CurrentChatUserControllerDelegate {
    func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUserUnreadCount: UnreadCount) {}

    func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUser: EntityChange<CurrentChatUser>) {}
}

public extension CurrentChatUserController {
    /// Set the delegate of `CurrentUserController` to observe the changes in the system.
    var delegate: CurrentChatUserControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }
}

// MARK: - Deprecations

public extension CurrentChatUserController {
    @available(
        *,
        deprecated,
        message: "use addDevice(_pushDevice:) instead. This deprecated function doesn't correctly support multiple push providers."
    )
    func addDevice(token: Data, pushProvider: PushProvider = .apn, completion: ((Error?) -> Void)? = nil) {
        addDevice(.apn(token: token), completion: completion)
    }
}
