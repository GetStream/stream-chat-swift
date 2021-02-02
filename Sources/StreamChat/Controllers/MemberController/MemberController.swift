//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension _ChatClient {
    /// Creates a new `_ChatChannelMemberController` for the user with the provided `userId` and `cid`.
    /// - Parameters:
    ///   - userId: The user identifier.
    ///   - cid: The channel identifier.
    /// - Returns: A new instance of `_ChatChannelMemberController`.
    func memberController(userId: UserId, in cid: ChannelId) -> _ChatChannelMemberController<ExtraData> {
        .init(userId: userId, cid: cid, client: self)
    }
}

/// `ChatChannelMemberController` is a controller class which allows mutating and observing changes of a specific chat member.
///
/// `ChatChannelMemberController` objects are lightweight, and they can be used for both, continuous data change observations,
/// and for quick user actions (like ban/unban).
///
/// - Note: `ChatChannelMemberController` is a typealias of `_ChatChannelMemberController` with default extra data.
/// If you're using custom extra data, create your own typealias of `_ChatChannelMemberController`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public typealias ChatChannelMemberController = _ChatChannelMemberController<NoExtraData>

/// `_ChatChannelMemberController` is a controller class which allows mutating and observing changes of a specific chat member.
///
/// `_ChatChannelMemberController` objects are lightweight, and they can be used for both, continuous data change observations,
/// and for quick user actions (like mute/unmute).
///
/// - Note: `ChatChannelMemberController` is a typealias of `_ChatChannelMemberController` with default extra data.
/// If you're using custom extra data, create your own typealias of `_ChatChannelMemberController`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public class _ChatChannelMemberController<ExtraData: ExtraDataTypes>: DataController, DelegateCallable, DataStoreProvider {
    /// The identifier of the user this controller observes.
    public let userId: UserId
    
    /// The identifier of the channel the user is member of.
    public let cid: ChannelId
    
    /// The `ChatClient` instance this controller belongs to.
    public let client: _ChatClient<ExtraData>
    
    /// The user the controller represents.
    ///
    /// To observe changes of the chat member, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    public var member: _ChatChannelMember<ExtraData.User>? {
        startObservingIfNeeded()
        return memberObserver.item
    }
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    @available(iOS 13, *)
    lazy var basePublishers: BasePublishers = .init(controller: self)
    
    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<AnyChatChannelMemberControllerDelegate<ExtraData>> = .init() {
        didSet {
            stateMulticastDelegate.mainDelegate = multicastDelegate.mainDelegate
            stateMulticastDelegate.additionalDelegates = multicastDelegate.additionalDelegates
            startObservingIfNeeded()
        }
    }
    
    /// The worker used to update channel members.
    private lazy var memberUpdater = createMemberUpdater()
    
    /// The worker used to fetch channel members.
    private lazy var memberListUpdater = createMemberListUpdater()
    
    /// The observer used to track the user changes in the database.
    private lazy var memberObserver = createMemberObserver()
        .onChange { [unowned self] change in
            self.delegateCallback {
                $0.memberController(self, didUpdateMember: change)
            }
        }
    
    private let environment: Environment

    /// Creates a new `_ChatChannelMemberController`
    /// - Parameters:
    ///   - userId: The user identifier.
    ///   - cid: The channel identifier the user is member of.
    ///   - client: The `Client` this controller belongs to.
    ///   - environment: Environment for this controller.
    init(
        userId: UserId,
        cid: ChannelId,
        client: _ChatClient<ExtraData>,
        environment: Environment = .init()
    ) {
        self.userId = userId
        self.cid = cid
        self.client = client
        self.environment = environment
    }
    
    override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
        startObservingIfNeeded()
        
        if case let .localDataFetchFailed(error) = state {
            callback { completion?(error) }
            return
        }
        
        memberListUpdater.load(.channelMember(userId: userId, cid: cid)) { error in
            self.state = error == nil ? .remoteDataFetched : .remoteDataFetchFailed(ClientError(with: error))
            self.callback { completion?(error) }
        }
    }
    
    /// Sets the provided object as a delegate of this controller.
    ///
    /// - Note: If you don't use custom extra data types, you can set the delegate directly using `controller.delegate = self`.
    /// Due to the current limits of Swift and the way it handles protocols with associated types, it's required to use this
    /// method to set the delegate, if you're using custom extra data types.
    ///
    /// - Parameter delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object
    /// alive if you want keep receiving updates.
    ///
    public func setDelegate<Delegate: _ChatChannelMemberControllerDelegate>(_ delegate: Delegate)
        where Delegate.ExtraData == ExtraData {
        multicastDelegate.mainDelegate = AnyChatChannelMemberControllerDelegate(delegate)
    }
    
    // MARK: - Private
    
    private func createMemberUpdater() -> ChannelMemberUpdater {
        environment.memberUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
    }
    
    private func createMemberListUpdater() -> ChannelMemberListUpdater<ExtraData> {
        environment.memberListUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
    }
    
    private func createMemberObserver() -> EntityDatabaseObserver<_ChatChannelMember<ExtraData.User>, MemberDTO> {
        environment.memberObserverBuilder(
            client.databaseContainer.viewContext,
            MemberDTO.member(userId, in: cid),
            { $0.asModel() },
            NSFetchedResultsController<MemberDTO>.self
        )
    }
    
    private func startObservingIfNeeded() {
        guard state == .initialized else { return }
        
        do {
            try memberObserver.startObserving()
            state = .localDataFetched
        } catch {
            log.error("Observing member with id <\(userId)> failed: \(error). Accessing `member` will always return `nil`")
            state = .localDataFetchFailed(ClientError(with: error))
        }
    }
}

// MARK: - Actions

public extension _ChatChannelMemberController {
    /// Bans the channel member for a specific # of minutes.
    /// - Parameters:
    ///   - timeoutInMinutes: The # of minutes the user should be banned for.
    ///   - reason: The ban reason.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    func ban(
        for timeoutInMinutes: Int? = nil,
        reason: String? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        memberUpdater.banMember(userId, in: cid, for: timeoutInMinutes, reason: reason) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Unbans the channel member.
    /// - Parameter completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                         If request fails, the completion will be called with an error.
    func unban(completion: ((Error?) -> Void)? = nil) {
        memberUpdater.unbanMember(userId, in: cid) { error in
            self.callback {
                completion?(error)
            }
        }
    }
}

extension _ChatChannelMemberController {
    struct Environment {
        var memberUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelMemberUpdater = ChannelMemberUpdater.init
        
        var memberListUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelMemberListUpdater<ExtraData> = ChannelMemberListUpdater.init
        
        var memberObserverBuilder: (
            _ context: NSManagedObjectContext,
            _ fetchRequest: NSFetchRequest<MemberDTO>,
            _ itemCreator: @escaping (MemberDTO) -> _ChatChannelMember<ExtraData.User>,
            _ fetchedResultsControllerType: NSFetchedResultsController<MemberDTO>.Type
        ) -> EntityDatabaseObserver<_ChatChannelMember<ExtraData.User>, MemberDTO> = EntityDatabaseObserver.init
    }
}

public extension _ChatChannelMemberController where ExtraData == NoExtraData {
    /// Set the delegate of `ChatMemberController` to observe the changes in the system.
    ///
    /// - Note: The delegate can be set directly only if you're **not** using custom extra data types. Due to the current
    /// limits of Swift and the way it handles protocols with associated types, it's required to use `setDelegate` method
    /// instead to set the delegate, if you're using custom extra data types.
    var delegate: ChatChannelMemberControllerDelegate? {
        get { multicastDelegate.mainDelegate?.wrappedDelegate as? ChatChannelMemberControllerDelegate }
        set { multicastDelegate.mainDelegate = AnyChatChannelMemberControllerDelegate(newValue) }
    }
}

// MARK: - Delegates

/// `ChatChannelMemberControllerDelegate` uses this protocol to communicate changes to its delegate.
///
/// This protocol can be used only when no custom extra data are specified. If you're using custom extra data types,
/// please use `_ChatChannelMemberControllerDelegate` instead.
///
public protocol ChatChannelMemberControllerDelegate: DataControllerStateDelegate {
    /// The controller observed a change in the `ChatChannelMember` entity.
    func memberController(
        _ controller: ChatChannelMemberController,
        didUpdateMember change: EntityChange<ChatChannelMember>
    )
}

public extension ChatChannelMemberControllerDelegate {
    func memberController(
        _ controller: ChatChannelMemberController,
        didUpdateMember change: EntityChange<ChatChannelMember>
    ) {}
}

// MARK: Generic Delegates

/// `_ChatChannelMemberController` uses this protocol to communicate changes to its delegate.
///
/// If you're **not** using custom extra data types, you can use a convenience version of this protocol
/// named `ChatChannelMemberControllerDelegate`, which hides the generic types, and make the usage easier.
///
public protocol _ChatChannelMemberControllerDelegate: DataControllerStateDelegate {
    associatedtype ExtraData: ExtraDataTypes
    
    /// The controller observed a change in the `_ChatChannelMember<ExtraData.User>` entity.
    func memberController(
        _ controller: _ChatChannelMemberController<ExtraData>,
        didUpdateMember change: EntityChange<_ChatChannelMember<ExtraData.User>>
    )
}

public extension _ChatChannelMemberControllerDelegate {
    func memberController(
        _ controller: _ChatChannelMemberController<ExtraData>,
        didUpdateMember change: EntityChange<_ChatChannelMember<ExtraData.User>>
    ) {}
}

// MARK: Type erased Delegate

class AnyChatChannelMemberControllerDelegate<ExtraData: ExtraDataTypes>: _ChatChannelMemberControllerDelegate {
    private var _controllerDidChangeState: (DataController, DataController.State) -> Void
    
    private var _controllerDidUpdateMember: (
        _ChatChannelMemberController<ExtraData>,
        EntityChange<_ChatChannelMember<ExtraData.User>>
    ) -> Void
    
    weak var wrappedDelegate: AnyObject?
    
    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeState: @escaping (DataController, DataController.State) -> Void,
        controllerDidUpdateMember: @escaping (
            _ChatChannelMemberController<ExtraData>,
            EntityChange<_ChatChannelMember<ExtraData.User>>
        ) -> Void
    ) {
        self.wrappedDelegate = wrappedDelegate
        _controllerDidChangeState = controllerDidChangeState
        _controllerDidUpdateMember = controllerDidUpdateMember
    }
    
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        _controllerDidChangeState(controller, state)
    }
    
    func memberController(
        _ controller: _ChatChannelMemberController<ExtraData>,
        didUpdateMember change: EntityChange<_ChatChannelMember<ExtraData.User>>
    ) {
        _controllerDidUpdateMember(controller, change)
    }
}

extension AnyChatChannelMemberControllerDelegate {
    convenience init<Delegate: _ChatChannelMemberControllerDelegate>(_ delegate: Delegate) where Delegate.ExtraData == ExtraData {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidUpdateMember: { [weak delegate] in delegate?.memberController($0, didUpdateMember: $1) }
        )
    }
}

extension AnyChatChannelMemberControllerDelegate where ExtraData == NoExtraData {
    convenience init(_ delegate: ChatChannelMemberControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidUpdateMember: { [weak delegate] in delegate?.memberController($0, didUpdateMember: $1) }
        )
    }
}
