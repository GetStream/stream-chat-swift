//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import XCTest

extension StreamMockServer {
    
    func configureChannelEndpoints() {
        server[MockEndpoint.query] = { [weak self] request in
            self?.updateChannelList(request) ?? .badRequest(nil)
        }
        server[MockEndpoint.channels] = { [weak self] request in
            self?.updateChannelList(request) ?? .badRequest(nil)
        }
    }
    
    func generateChannels(
        count: Int,
        authorDetails: [String: String] = UserDetails.lukeSkywalker,
        membersDetails: [[String: String]] = [
            UserDetails.lukeSkywalker, UserDetails.hanSolo, UserDetails.countDooku
        ]
    ) {
        var json = channelList
        let userSources = TestData.toJson(.httpChatEvent)[TopLevelKey.event] as! [String: Any]
        let sampleChannel = (json[TopLevelKey.channels] as! [[String: Any]]).first!
        
        let members = mockMembers(
            userSources: userSources,
            sampleChannel: sampleChannel,
            membersDetails: membersDetails
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
        
        if let id = request.params[EndpointQuery.channelId] {
            var channels = json[TopLevelKey.channels] as! [[String: Any]]
            if let index = channels.firstIndex(where: {
                let channel = $0[ChannelPayload.CodingKeys.channel.rawValue] as! [String: Any]
                return (channel[ChannelCodingKeys.id.rawValue] as? String) == id
            }) {
                let messageList = findMessagesByChannelId(id)
                channels[index][ChannelQuery.CodingKeys.messages.rawValue] = messageList
                json[TopLevelKey.channels] = channels
                currentChannelId = id
                channelList = json
            }
        }
        
        return .ok(.json(json))
    }
    
    private func mockMembers(
        userSources: [String: Any],
        sampleChannel: [String: Any],
        membersDetails: [[String: String]]
    ) -> [[String: Any]] {
        var sampleMember = (sampleChannel[ChannelPayload.CodingKeys.members.rawValue] as! [[String: Any]]).first!
        var members: [[String: Any]] = []
        for member in membersDetails {
            sampleMember[TopLevelKey.user] = setUpUser(source: userSources, details: member)
            sampleMember[TopLevelKey.userId] = member[UserPayloadsCodingKeys.id.rawValue]
            members.append(sampleMember)
        }
        return members
    }
    
    private func mockChannels(
        count: Int,
        author: [String: Any],
        members: [[String: Any]],
        sampleChannel: [String: Any]
    ) -> [[String: Any]] {
        var channels: [[String: Any]] = []
        
        if count > 0 {
            var channelDetails = sampleChannel[ChannelPayload.CodingKeys.channel.rawValue] as! [String: Any]
            var membership = sampleChannel[ChannelPayload.CodingKeys.membership.rawValue] as! [String: Any]
            membership[TopLevelKey.user] = author
            
            for _ in 1...count {
                var newChannel = sampleChannel
                let uniqueId = TestData.uniqueId
                channelDetails[ChannelCodingKeys.name.rawValue] = uniqueId
                channelDetails[ChannelCodingKeys.id.rawValue] = uniqueId
                channelDetails[ChannelCodingKeys.cid.rawValue] = "\(ChannelType.messaging.rawValue):\(uniqueId)"
                channelDetails[ChannelCodingKeys.createdBy.rawValue] = author
                channelDetails[ChannelCodingKeys.memberCount.rawValue] = members.count
                newChannel[ChannelPayload.CodingKeys.members.rawValue] = members
                newChannel[ChannelPayload.CodingKeys.membership.rawValue] = membership
                newChannel[ChannelPayload.CodingKeys.channel.rawValue] = channelDetails
                channels.append(newChannel)
            }
        }
        
        return channels
    }
    
}
