//
//  Client+Requests.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 02/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Channels Requests

public extension Client {
    
    /// A message search.
    /// - Parameters:
    ///   - filter: a filter for channels, e.g. .key("members", .in(["john"]))
    ///   - query: a search query.
    ///   - pagination: a pagination. It works via the standard limit and offset parameters.
    func search(filter: Filter = .none, query: String, pagination: Pagination = .channelsPageSize) -> Observable<[Message]> {
        guard !query.isBlank else {
            return .empty()
        }
        
        let query = SearchQuery(filter: filter, query: query, pagination: pagination)
        
        if case .none = query.filter {
            return .error(SearchQueryError.emptyFilter)
        }
        
        let request: Observable<SearchResponse> = rx.request(endpoint: .search(query))
        
        return connectedRequest(request.map { $0.messages.compactMap({ $0["message"] }) })
    }
    
    /// Requests channels with a given query.
    ///
    /// - Parameter query: a channels query (see `ChannelsQuery`).
    /// - Returns: a list of a channel response (see `ChannelResponse`).
    func channels(query: ChannelsQuery) -> Observable<[ChannelResponse]> {
        let request: Observable<ChannelsResponse> = rx.request(endpoint: .channels(query))
        return connectedRequest(request.map { $0.channels })
            .do(onNext: { [unowned self] in self.add(channelsToDatabase: $0, query: query) })
    }
    
    /// Requests channel with a given query.
    ///
    /// - Parameter query: a channels query (see `ChannelsQuery`).
    /// - Returns: a list of a channel response (see `ChannelResponse`).
    func channel(query: ChannelQuery) -> Observable<ChannelResponse> {
        return connectedRequest(.channel(query))
            .do(onNext: { channelResponse in
                if query.options.contains(.state) {
                    channelResponse.channel.add(messagesToDatabase: channelResponse.messages)
                }
            })
    }
    
    /// Get a message by id.
    /// - Parameter messageId: a message id.
    func message(with messageId: String) -> Observable<MessageResponse> {
        return connectedRequest(.message(messageId))
    }
    
    /// Mark all messages as readed.
    func markAllRead() -> Observable<Void> {
        let request: Observable<EmptyData> = rx.request(endpoint: .markAllRead)
        return connectedRequest(request.map({ _ in Void() }))
    }
}

// MARK: - Users Requests

public extension Client {
    
    /// Requests users with a given query.
    ///
    /// - Parameter query: a users query (see `UsersQuery`).
    /// - Returns: an observable list of users.
    func users(query: UsersQuery) -> Observable<[User]> {
        let request: Observable<UsersResponse> = rx.request(endpoint: .users(query))
        return connectedRequest(request.map({ $0.users }))
    }
    
    // MARK: Update User
    
    /// Update or create a user.
    ///
    /// - Returns: an observable updated user.
    func update(users: [User]) -> Observable<[User]> {
        let request: Observable<UpdatedUsersResponse> = rx.request(endpoint: .updateUsers(users))
        return connectedRequest(request.map({ $0.users.values.map { $0 } }))
    }
    
    /// Update or create a user.
    ///
    /// - Parameter user: a user.
    /// - Returns: an observable updated user.
    func update(user: User) -> Observable<User> {
        return update(users: [user]).compactMap({ $0.first })
    }
    
    // MARK: Mute User
    
    /// Mute a user.
    ///
    /// - Parameter user: a user.
    /// - Returns: an observable muted user.
    func mute(user: User) -> Observable<MutedUsersResponse> {
        return user.mute()
    }
    
    /// Unmute a user.
    ///
    /// - Parameter user: a user.
    /// - Returns: an observable unmuted user.
    func unmute(user: User) -> Observable<Void> {
        return user.unmute()
    }
    
    // MARK: Flag User
    
    /// Flag a user.
    /// - Parameter user: a user.
    func flag(user: User) -> Observable<FlagUserResponse> {
        return user.flag()
    }
    
    /// Unflag a user.
    /// - Parameter user: a user.
    func unflag(user: User) -> Observable<FlagUserResponse> {
        return user.unflag()
    }
    
    func flagUnflag<T: Decodable>(endpoint: Endpoint, aleradyFlagged value: T) -> Observable<T> {
        let request: Observable<FlagResponse<T>> = rx.request(endpoint: endpoint)
        
        return request.map { $0.flag }
            .catchError { error -> Observable<T> in
                if let clientError = error as? ClientError,
                    case .responseError(let clientResponseError) = clientError,
                    clientResponseError.message.contains("flag already exists") {
                    return .just(value)
                }
                
                return .error(error)
        }
    }
}
