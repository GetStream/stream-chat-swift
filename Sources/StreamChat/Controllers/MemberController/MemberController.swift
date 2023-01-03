//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension ChatClient {
    /// Creates a new `ChatChannelMemberController` for the user with the provided `userId` and `cid`.
    /// - Parameters:
    ///   - userId: The user identifier.
    ///   - cid: The channel identifier.
    /// - Returns: A new instance of `ChatChannelMemberController`.
    func memberController(userId: UserId, in cid: ChannelId) -> ChatChannelMemberController {
        .init(userId: userId, cid: cid, client: self)
    }
}

/// `ChatChannelMemberController` is a controller class which allows mutating and observing changes of a specific chat member.
///
public class ChatChannelMemberController: DataController, DelegateCallable, DataStoreProvider {
    /// The identifier of the user this controller observes.
    public let userId: UserId

    /// The identifier of the channel the user is member of.
    public let cid: ChannelId

    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    /// The user the controller represents.
    ///
    /// To observe changes of the chat member, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    public var member: ChatChannelMember? {
        startObservingIfNeeded()
        return memberObserver.item
    }

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

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<ChatChannelMemberControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)
            startObservingIfNeeded()
        }
    }

    /// The worker used to update channel members.
    private lazy var memberUpdater = createMemberUpdater()

    /// The worker used to fetch channel members.
    private lazy var memberListUpdater = createMemberListUpdater()

    /// The observer used to track the user changes in the database.
    private lazy var memberObserver = createMemberObserver()
        .onChange { [weak self] change in
            self?.delegateCallback { [weak self] in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }

                $0.memberController(self, didUpdateMember: change)
            }
        }

    private let environment: Environment

    /// Creates a new `ChatChannelMemberController`
    /// - Parameters:
    ///   - userId: The user identifier.
    ///   - cid: The channel identifier the user is member of.
    ///   - client: The `Client` this controller belongs to.
    ///   - environment: Environment for this controller.
    init(
        userId: UserId,
        cid: ChannelId,
        client: ChatClient,
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

    // MARK: - Private

    private func createMemberUpdater() -> ChannelMemberUpdater {
        environment.memberUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
    }

    private func createMemberListUpdater() -> ChannelMemberListUpdater {
        environment.memberListUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
    }

    private func createMemberObserver() -> EntityDatabaseObserver<ChatChannelMember, MemberDTO> {
        environment.memberObserverBuilder(
            client.databaseContainer.viewContext,
            MemberDTO.member(userId, in: cid),
            { try $0.asModel() },
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

public extension ChatChannelMemberController {
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

extension ChatChannelMemberController {
    struct Environment {
        var memberUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelMemberUpdater = ChannelMemberUpdater.init

        var memberListUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelMemberListUpdater = ChannelMemberListUpdater.init

        var memberObserverBuilder: (
            _ context: NSManagedObjectContext,
            _ fetchRequest: NSFetchRequest<MemberDTO>,
            _ itemCreator: @escaping (MemberDTO) throws -> ChatChannelMember,
            _ fetchedResultsControllerType: NSFetchedResultsController<MemberDTO>.Type
        ) -> EntityDatabaseObserver<ChatChannelMember, MemberDTO> = EntityDatabaseObserver.init
    }
}

public extension ChatChannelMemberController {
    /// Set the delegate of `ChatMemberController` to observe the changes in the system.
    var delegate: ChatChannelMemberControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }
}

// MARK: - Delegates

/// `ChatChannelMemberControllerDelegate` uses this protocol to communicate changes to its delegate.
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
