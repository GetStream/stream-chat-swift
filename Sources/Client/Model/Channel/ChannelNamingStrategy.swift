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
            guard members.count > 1, let currentUserIndex = members.firstIndex(of: currentUser) else {
                return nil
            }
            
            var otherMembers = members
            otherMembers.remove(at: currentUserIndex)
            
            var extraData = ChannelExtraData()
            extraData.name = name(from: otherMembers)
            extraData.imageURL = imageURL(from: otherMembers)
            
            return extraData
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
            otherMembers.count == 1 ? otherMembers.first?.avatarURL : nil
        }
    }
}
