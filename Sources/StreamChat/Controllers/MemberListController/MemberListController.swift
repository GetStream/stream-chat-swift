//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

extension ChatClient {
    /// Creates a new `ChatChannelMemberListController` with the provided query.
    /// - Parameter query: The query specify the filter and sorting options for members the controller should fetch.
    /// - Returns: A new instance of `ChatChannelMemberListController`.
    public func memberListController(
        query: ChannelMemberListQuery
    ) -> ChatChannelMemberListController<ExtraData> {
        .init(query: query, client: self)
    }
}

/// `ChatChannelMemberListController` is a controller class which allows observing a list of
/// channel members based on the provided query.
///
/// Learn more about `ChatChannelMemberListController` and its usage in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#user-list).
///
/// - Note: `ChatChannelMemberListController` is a typealias of `ChatChannelMemberListController` with default extra data.
/// If you're using custom extra data, create your own typealias of `ChatChannelMemberListController`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
public typealias ChatChannelMemberListController = ChatChannelMemberListController<NoExtraData>

/// `ChatChannelMemberListController` is a controller class which allows observing
/// a list of chat users based on the provided query.
///
/// Learn more about `ChatChannelMemberListController` and its usage in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#user-list).
///
/// - Note: `ChatChannelMemberListController` type is not meant to be used directly. If you're using default extra data, use
/// `ChatChannelMemberListController` typealias instead. If you're using custom extra data, create your own typealias
/// of `ChatChannelMemberListController`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
public class ChatChannelMemberListController<ExtraData: ExtraDataTypes>: DataController, DelegateCallable, DataStoreProvider {
    /// The query specifying sorting and filtering for the list of channel members.
    @Atomic public private(set) var query: ChannelMemberListQuery
    
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient
    
    /// The channel members matching the query.
    /// To observe the member list changes, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    public var members: LazyCachedMapCollection<ChatChannelMember> {
        startObservingIfNeeded()
        return memberListObserver.items
    }
    
    /// The worker used to fetch the remote data and communicate with servers.
    private lazy var memberListUpdater = createMemberListUpdater()

    /// The observer used to observe the changes in the database.
    private lazy var memberListObserver = createMemberListObserver()
    
    /// The type-erased delegate.
    var multicastDelegate: MulticastDelegate<AnyChatChannelMemberListControllerDelegate<ExtraData>> = .init() {
        didSet {
            stateMulticastDelegate.mainDelegate = multicastDelegate.mainDelegate
            stateMulticastDelegate.additionalDelegates = multicastDelegate.additionalDelegates
            startObservingIfNeeded()
        }
    }
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    @available(iOS 13, *)
    lazy var basePublishers: BasePublishers = .init(controller: self)
    
    private let environment: Environment
    
    /// Creates a new `ChatChannelMemberListController`
    /// - Parameters:
    ///   - query: The query used for filtering and sorting the channel members.
    ///   - client: The `Client` this controller belongs to.
    ///   - environment: Environment for this controller.
    init(query: ChannelMemberListQuery, client: ChatClient, environment: Environment = .init()) {
        self.client = client
        self.query = query
        self.environment = environment
    }
    
    override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
        startObservingIfNeeded()
        
        if case let .localDataFetchFailed(error) = state {
            callback { completion?(error) }
            return
        }
        
        memberListUpdater.load(query) { error in
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
    public func setDelegate<Delegate: ChatChannelMemberListControllerDelegate>(_ delegate: Delegate)
        where Delegate.ExtraData == ExtraData {
        multicastDelegate.mainDelegate = AnyChatChannelMemberListControllerDelegate(delegate)
    }
    
    private func createMemberListUpdater() -> ChannelMemberListUpdater {
        environment.memberListUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
    }
    
    private func createMemberListObserver() -> ListDatabaseObserver<ChatChannelMember, MemberDTO> {
        let observer = environment.memberListObserverBuilder(
            client.databaseContainer.viewContext,
            MemberDTO.members(matching: query),
            { $0.asModel() },
            NSFetchedResultsController<MemberDTO>.self
        )
        
        observer.onChange = { [unowned self] changes in
            self.delegateCallback {
                $0.memberListController(self, didChangeMembers: changes)
            }
        }
        
        return observer
    }
    
    private func startObservingIfNeeded() {
        guard state == .initialized else { return }
        
        do {
            try memberListObserver.startObserving()
            state = .localDataFetched
        } catch {
            log.error("Observing members matching <\(query)> failed: \(error). Accessing `members` will always return `[]`.")
            state = .localDataFetchFailed(ClientError(with: error))
        }
    }
}

// MARK: - Actions

public extension ChatChannelMemberListController {
    /// Loads next members from backend.
    /// - Parameters:
    ///   - limit: The page size.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    func loadNextMembers(
        limit: Int = 25,
        completion: ((Error?) -> Void)? = nil
    ) {
        var updatedQuery = query
        updatedQuery.pagination = Pagination(pageSize: limit, offset: members.count)
        memberListUpdater.load(updatedQuery) { error in
            self.query = updatedQuery
            self.callback {
                completion?(error)
            }
        }
    }
}

extension ChatChannelMemberListController {
    struct Environment {
        var memberListUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelMemberListUpdater = ChannelMemberListUpdater.init

        var memberListObserverBuilder: (
            _ context: NSManagedObjectContext,
            _ fetchRequest: NSFetchRequest<MemberDTO>,
            _ itemCreator: @escaping (MemberDTO) -> ChatChannelMember,
            _ controllerType: NSFetchedResultsController<MemberDTO>.Type
        ) -> ListDatabaseObserver<ChatChannelMember, MemberDTO> = ListDatabaseObserver.init
    }
}

extension ChatChannelMemberListController where ExtraData == NoExtraData {
    /// Set the delegate of `ChatChannelMemberListController` to observe the changes in the system.
    ///
    /// - Note: The delegate can be set directly only if you're **not** using custom extra data types. Due to the current
    /// limits of Swift and the way it handles protocols with associated types, it's required to use `setDelegate` method
    /// instead to set the delegate, if you're using custom extra data types.
    public var delegate: ChatChannelMemberListControllerDelegate? {
        get { multicastDelegate.mainDelegate?.wrappedDelegate as? ChatChannelMemberListControllerDelegate }
        set { multicastDelegate.mainDelegate = AnyChatChannelMemberListControllerDelegate(newValue) }
    }
}

/// `ChatChannelMemberListController` uses this protocol to communicate changes to its delegate.
///
/// This protocol can be used only when no custom extra data are specified. If you're using custom extra data types,
/// please use `ChatChannelMemberListControllerDelegate` instead.
public protocol ChatChannelMemberListControllerDelegate: DataControllerStateDelegate {
    /// Controller observed a change in the channel member list.
    func memberListController(
        _ controller: ChatChannelMemberListController,
        didChangeMembers changes: [ListChange<ChatChannelMember>]
    )
}

public extension ChatUserListControllerDelegate {
    func memberListController(
        _ controller: ChatChannelMemberListController,
        didChangeMembers changes: [ListChange<ChatChannelMember>]
    ) {}
}

/// `ChatChannelMemberListController` uses this protocol to communicate changes to its delegate.
///
/// If you're **not** using custom extra data types, you can use a convenience version of this protocol
/// named `ChatChannelMemberListControllerDelegate`, which hides the generic types, and make the usage easier.
///
public protocol ChatChannelMemberListControllerDelegate: DataControllerStateDelegate {
    associatedtype ExtraData: ExtraDataTypes
    
    /// Controller observed a change in the channel member list.
    func memberListController(
        _ controller: ChatChannelMemberListController<ExtraData>,
        didChangeMembers changes: [ListChange<ChatChannelMember>]
    )
}

public extension ChatChannelMemberListControllerDelegate {
    func memberListController(
        _ controller: ChatChannelMemberListController<ExtraData>,
        didChangeMembers changes: [ListChange<ChatChannelMember>]
    ) {}
}

// MARK: - Delegate type eraser

final class AnyChatChannelMemberListControllerDelegate<ExtraData: ExtraDataTypes>: ChatChannelMemberListControllerDelegate {
    private let _controllerDidChangeState: (DataController, DataController.State) -> Void
    
    private let _controllerDidChangeMembers: (
        ChatChannelMemberListController<ExtraData>,
        [ListChange<ChatChannelMember>]
    ) -> Void
    
    weak var wrappedDelegate: AnyObject?
    
    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeState: @escaping (DataController, DataController.State) -> Void,
        controllerDidChangeMembers: @escaping (
            ChatChannelMemberListController<ExtraData>,
            [ListChange<ChatChannelMember>]
        ) -> Void
    ) {
        self.wrappedDelegate = wrappedDelegate
        _controllerDidChangeState = controllerDidChangeState
        _controllerDidChangeMembers = controllerDidChangeMembers
    }

    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        _controllerDidChangeState(controller, state)
    }

    func memberListController(
        _ controller: ChatChannelMemberListController<ExtraData>,
        didChangeMembers changes: [ListChange<ChatChannelMember>]
    ) {
        _controllerDidChangeMembers(controller, changes)
    }
}

extension AnyChatChannelMemberListControllerDelegate {
    convenience init<Delegate: ChatChannelMemberListControllerDelegate>(_ delegate: Delegate)
        where Delegate.ExtraData == ExtraData {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in
                delegate?.controller($0, didChangeState: $1)
            },
            controllerDidChangeMembers: { [weak delegate] in
                delegate?.memberListController($0, didChangeMembers: $1)
            }
        )
    }
}

extension AnyChatChannelMemberListControllerDelegate where ExtraData == NoExtraData {
    convenience init(_ delegate: ChatChannelMemberListControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in
                delegate?.controller($0, didChangeState: $1)
            },
            controllerDidChangeMembers: { [weak delegate] in
                delegate?.memberListController($0, didChangeMembers: $1)
            }
        )
    }
}
