//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

extension _ChatChannel: ProvidesNameAndImage {
    var name: String? {
        if let extraData = extraData as? NameAndImageExtraData {
            return extraData.name
        }
        return nil
    }
    
    var imageURL: URL? {
        if let extraData = extraData as? NameAndImageExtraData {
            return extraData.imageURL
        }
        return nil
    }
}

open class ChatUIChannelModel {
    /// The `ChannelId` of the channel.
    public let cid: ChannelId
    
    /// The date of the last message in the channel.
    public let lastMessageAt: Date?
    
    /// The date when the channel was created.
    public let createdAt: Date
    
    /// The date when the channel was updated.
    public let updatedAt: Date
    
    /// If the channel was deleted, this field contains the date of the deletion.
    public let deletedAt: Date?
    
    /// The user which created the channel.
    public let createdBy: ChatUIUser?
    
    /// A configuration struct of the channel. It contains additional information about the channel settings.
    public let config: ChannelConfig
    
    /// Returns `true` if the channel is frozen.
    ///
    /// It's not possible to send new messages to a frozen channel.
    ///
    public let isFrozen: Bool
    
    /// The total number of members in the channel.
    public let memberCount: Int
    
    /// A list of locally cached members objects.
    ///
    /// - Important: This list doesn't have to contain all members of the channel. To access the full list of members, create
    /// a `ChatChannelController` for this channel and use it to query all channel members.
    ///
    public let cachedMembers: Set<ChatUIChannelMember>
    
    /// A list of currently typing channel members.
    public let currentlyTypingMembers: Set<ChatUIChannelMember>
    
    /// A list of channel members currently online actively watching the channel.
    public let watchers: Set<ChatUIUser>
    
    /// The total number of online members watching this channel.
    public let watcherCount: Int
    
    /// The team the channel belongs to.
    ///
    /// You need to enable multi-tenancy if you want to use this, else it'll be nil.
    /// Refer to [docs](https://getstream.io/chat/docs/multi_tenant_chat/?language=swift) for more info.
    ///
    //    public let team: String
    
    /// The unread counts for the channel.
    public let unreadCount: ChannelUnreadCount
    
    /// An option to enable ban users.
    //    public let banEnabling: BanEnabling
    
    /// Latest messages present on the channel.
    ///
    /// This field contains only the latest messages of the channel. You can get all existing messages in the channel by creating
    /// and using a `ChatChannelController` for this channel id.
    ///
    public let latestMessages: [ChatUIMessage]
    
    /// Read states of the users for this channel.
    ///
    /// You can use this information to show to your users information about what messages were read by certain users.
    ///
    public let reads: [ChatUIChannelRead]
    
    init<ExtraData: ExtraDataTypes>(config: UIModelConfig = .default, channel: _ChatChannel<ExtraData>) {
        cid = channel.cid
        lastMessageAt = channel.lastMessageAt
        createdAt = channel.createdAt
        updatedAt = channel.updatedAt
        deletedAt = channel.deletedAt
        createdBy = channel.createdBy.map { config.userModelType.init(user: $0, name: $0.name, imageURL: $0.imageURL) }
        self.config = channel.config
        isFrozen = channel.isFrozen
        cachedMembers = Set(
            channel.cachedMembers
                .map { config.channelMemberModelType.init(member: $0, name: $0.name, imageURL: $0.imageURL) }
        )
        currentlyTypingMembers = Set(
            channel.currentlyTypingMembers
                .map { config.channelMemberModelType.init(member: $0, name: $0.name, imageURL: $0.imageURL) }
        )
        watchers = Set(channel.watchers.map { config.userModelType.init(user: $0, name: $0.name, imageURL: $0.imageURL) })
        unreadCount = channel.unreadCount
        watcherCount = channel.watcherCount
        memberCount = channel.memberCount
        reads = channel.reads.map { config.channelReadModelType.init(config: config, channelRead: $0) }
        latestMessages = channel.latestMessages.map { config.messageModelType.init(config: config, message: $0) }
    }
}

open class ChatUIChannel: ChatUIChannelModel, ProvidesNameAndImage {
    let name: String?
    let imageURL: URL?
    
    public required init<ExtraData: ExtraDataTypes>(
        config: UIModelConfig = .default,
        channel: _ChatChannel<ExtraData>,
        name: String?,
        imageURL: URL?
    ) {
        self.name = name
        self.imageURL = imageURL
        super.init(config: config, channel: channel)
    }
}
