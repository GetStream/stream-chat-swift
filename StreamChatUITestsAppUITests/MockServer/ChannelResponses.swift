//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import XCTest

extension StreamMockServer {
    
    func configureChannelEndpoints() {
        server.register(MockEndpoint.query) { [weak self] request in
            self?.updateChannelList(request)
        }
        server.register(MockEndpoint.channels) { [weak self] request in
            self?.updateChannelList(request)
        }
    }
    
    func generateChannels(
        count: Int,
        authorDetails: [String: String] = UserDetails.lukeSkywalker,
        memberDetails: [[String: String]] = [
            UserDetails.lukeSkywalker, UserDetails.hanSolo, UserDetails.countDooku
        ]
    ) {
        var json = channelList
        guard let sampleChannel = (json[TopLevelKey.channels] as? [[String: Any]])?.first else { return }
        
        let userSources = TestData.toJson(.httpChatEvent)[TopLevelKey.event] as? [String: Any]
        
        let members = mockMembers(
            userSources: userSources,
            sampleChannel: sampleChannel,
            memberDetails: memberDetails
        )
        
        let author = setUpUser(source: userSources, details: authorDetails)
        let channels = mockChannels(
            count: count,
            author: author,
            members: members,
            sampleChannel: sampleChannel
        )
        
        json[TopLevelKey.channels] = channels
        channelList = json
    }
    
    private func updateChannelList(_ request: HttpRequest) -> HttpResponse {
        var json = channelList
        guard let id = request.params[EndpointQuery.channelId] else { return .ok(.json(json)) }
        
        var channels = json[TopLevelKey.channels] as? [[String: Any]]
        if let index = channels?.firstIndex(where: {
            let channel = $0[ChannelPayload.CodingKeys.channel.rawValue] as? [String: Any]
            return (channel?[ChannelCodingKeys.id.rawValue] as? String) == id
        }) {
            let messageList = findMessagesByChannelId(id)
            channels?[index][ChannelQuery.CodingKeys.messages.rawValue] = messageList
            json[TopLevelKey.channels] = channels
            currentChannelId = id
            channelList = json
        }
        
        return .ok(.json(json))
    }
    
    private func mockMembers(
        userSources: [String: Any]?,
        sampleChannel: [String: Any],
        memberDetails: [[String: String]]
    ) -> [[String: Any]] {
        var members: [[String: Any]] = []
        let channelMembers = sampleChannel[ChannelPayload.CodingKeys.members.rawValue] as? [[String: Any]]
        guard var sampleMember = channelMembers?.first else { return members }
        
        for member in memberDetails {
            sampleMember[TopLevelKey.user] = setUpUser(source: userSources, details: member)
            sampleMember[TopLevelKey.userId] = member[UserPayloadsCodingKeys.id.rawValue]
            members.append(sampleMember)
        }
        return members
    }
    
    private func mockChannels(
        count: Int,
        author: [String: Any]?,
        members: [[String: Any]],
        sampleChannel: [String: Any]
    ) -> [[String: Any]] {
        var channels: [[String: Any]] = []
        guard count > 0 else { return channels }
        
        var membership = sampleChannel[ChannelPayload.CodingKeys.membership.rawValue] as? [String: Any]
        membership?[TopLevelKey.user] = author
        
        for _ in 1...count {
            var newChannel = sampleChannel
            newChannel[ChannelPayload.CodingKeys.members.rawValue] = members
            newChannel[ChannelPayload.CodingKeys.membership.rawValue] = membership
            newChannel[ChannelPayload.CodingKeys.channel.rawValue] = mockChannelDetails(
                channel: newChannel,
                author: author,
                memberCount: members.count
            )
            channels.append(newChannel)
        }
        
        return channels
    }
    
    private func mockChannelDetails(
        channel: [String: Any],
        author: [String: Any]?,
        memberCount: Int
    ) -> [String: Any]? {
        var channelDetails = channel[ChannelPayload.CodingKeys.channel.rawValue] as? [String: Any]
        let uniqueId = TestData.uniqueId
        channelDetails?[ChannelCodingKeys.name.rawValue] = uniqueId
        channelDetails?[ChannelCodingKeys.id.rawValue] = uniqueId
        channelDetails?[ChannelCodingKeys.cid.rawValue] = "\(ChannelType.messaging.rawValue):\(uniqueId)"
        channelDetails?[ChannelCodingKeys.createdBy.rawValue] = author
        channelDetails?[ChannelCodingKeys.memberCount.rawValue] = memberCount
        return channelDetails
    }
    
}
