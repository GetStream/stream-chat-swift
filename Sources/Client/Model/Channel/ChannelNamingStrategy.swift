//
//  ChannelNamingStrategy.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 18/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// Describes a way to get the default channel name and image with an empty channel id and a list of members.
public protocol ChannelNamingStrategy {
    
    /// Returns a channel extra data with default name and image based on the current user and members.
    /// - Parameters:
    ///   - currentUser: the current user.
    ///   - members: members of the channel.
    func extraData(for currentUser: User, members: [User]) -> ChannelExtraDataCodable?
    
    /// Returns a channel name based on the current user and members.
    /// - Parameters:
    ///   - currentUser: the current user.
    ///   - members: members of the channel.
    func name(for currentUser: User, members: [User]) -> String?
    
    /// Returns a channel image based on the current user and members.
    /// - Parameters:
    ///   - currentUser: the current user.
    ///   - members: members of the channel.
    func imageURL(for currentUser: User, members: [User]) -> URL?
}

extension Channel {
    /// The default implementation for `ChannelNamingStrategy`.
    public struct DefaultNamingStrategy: ChannelNamingStrategy {
        
        let maxUserNames: Int
        
        /// Init a default channel naming strategy.
        /// - Parameter maxUserNames: a max number of user names to use in channel name,
        ///                           e.g. `John, Michael and 3 more` for `maxUserNames`: 2.
        public init(maxUserNames: Int) {
            self.maxUserNames = maxUserNames
        }
        
        public func extraData(for currentUser: User, members: [User]) -> ChannelExtraDataCodable? {
            let membersExcludingCurrentUser = otherMembers(for: currentUser, allMembers: members)
            
            var extraData = ChannelExtraData()
            extraData.name = name(from: membersExcludingCurrentUser)
            extraData.imageURL = imageURL(from: membersExcludingCurrentUser)
            
            return extraData
        }
        
        /// Generate names like this: "John", "John, Michael" or "John, Michael, Scott and 3 more".
        public func name(for currentUser: User, members: [User]) -> String? {
            let membersExcludingCurrentUser = otherMembers(for: currentUser, allMembers: members)
            return name(from: membersExcludingCurrentUser)
        }
        
        public func imageURL(for currentUser: User, members: [User]) -> URL? {
            let membersExcludingCurrentUser = otherMembers(for: currentUser, allMembers: members)
            return imageURL(from: membersExcludingCurrentUser)
        }
        
        /// Generate names like this: "John", "John, Michael" or "John, Michael, Scott and 3 more".
        private func name(from otherMembers: [User]) -> String? {
            guard !otherMembers.isEmpty else {
                return nil
            }
            
            guard maxUserNames > 0 else {
                return otherMembers.count == 1 ? "1 member" : "\(otherMembers.count) members"
            }
            
            let names = otherMembers.compactMap({ $0.name })
            let firstNames = names.prefix(maxUserNames)
            
            // Concat the first `maxUserNames` user names by a comma.
            return firstNames.joined(separator: ", ")
                // Add a number of other members count.
                + (names.count > maxUserNames ? " and \(names.count - maxUserNames) more" : "")
        }
        
        private func imageURL(from otherMembers: [User]) -> URL? {
            otherMembers.first?.avatarURL
        }
        
        private func otherMembers(for currentUser: User, allMembers: [User]) -> [User] {
            guard allMembers.count > 1, let currentUserIndex = allMembers.firstIndex(of: currentUser) else {
                return allMembers
            }
            
            var otherMembers = allMembers
            otherMembers.remove(at: currentUserIndex)
            return otherMembers.sorted(by: { $0.id < $1.id })
        }
    }
}
