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
    ) -> ChatChannelMemberListController {
        .init(query: query, client: self)
    }
}

/// `ChatChannelMemberListController` is a controller class which allows observing
/// a list of chat users based on the provided query.
public class ChatChannelMemberListController: DataController, DelegateCallable, DataStoreProvider {
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
    var multicastDelegate: MulticastDelegate<ChatChannelMemberListControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            multicastDelegate.additionalDelegates.forEach {
                stateMulticastDelegate.add(additionalDelegate: $0)
            }
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
    /// - Parameter delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object
    /// alive if you want keep receiving updates.
    ///
    public func setDelegate<Delegate: ChatChannelMemberListControllerDelegate>(_ delegate: Delegate) {
        multicastDelegate.set(mainDelegate: delegate)
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
        
        observer.onChange = { [weak self] changes in
            self?.delegateCallback { [weak self] in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }

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

extension ChatChannelMemberListController {
    /// Set the delegate of `ChatChannelMemberListController` to observe the changes in the system.
    public var delegate: ChatChannelMemberListControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }
}

/// `ChatChannelMemberListController` uses this protocol to communicate changes to its delegate.
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

public extension ChatChannelMemberListControllerDelegate {
    func memberListController(
        _ controller: ChatChannelMemberListController,
        didChangeMembers changes: [ListChange<ChatChannelMember>]
    ) {}
}
