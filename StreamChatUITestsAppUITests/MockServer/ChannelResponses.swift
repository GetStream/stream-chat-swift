//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import XCTest

extension StreamMockServer {

    private enum ChannelRequestType {
        case addMembers([String])
        case removeMembers([String])

        static func type(from body: [UInt8]) -> ChannelRequestType? {
            let json = TestData.toJson(body)

            // Add members
            if let ids = json[JSONKey.Channel.addMembers] as? [String] {
                return .addMembers(ids)
            }

            // Remove members
            if let ids = json[JSONKey.Channel.removeMembers] as? [String] {
                return .removeMembers(ids)
            }

            return nil
        }

        var eventType: EventType {
            switch self {
            case .addMembers:
                return .memberAdded
            case .removeMembers:
                return .memberRemoved
            }
        }

        var ids: [String] {
            switch self {
            case .addMembers(let ids),
                 .removeMembers(let ids):
                return ids
            }
        }
    }
    
    func configureChannelEndpoints() {
        server.register(MockEndpoint.query) { [weak self] request in
            self?.updateChannelList(request)
        }
        server.register(MockEndpoint.channels) { [weak self] request in
            self?.updateChannelList(request)
        }
        server.register(MockEndpoint.channel) { [weak self] request in
            self?.handleChannelRequest(request)
        }
    }

    func channelIndex(withId id: String) -> Int? {
        guard
            let channels = channelList[JSONKey.channels] as? [[String: Any]],
            let index = channels.firstIndex(
                where: {
                    let channel = $0[ChannelPayload.CodingKeys.channel.rawValue] as? [String: Any]
                    return (channel?[ChannelCodingKeys.id.rawValue] as? String) == id
                })
        else {
            return nil
        }

        return index
    }

    func channel(withId id: String) -> [String: Any]? {
        guard
            let channels = channelList[JSONKey.channels] as? [[String: Any]],
            let index = channelIndex(withId: id)
        else {
            return nil
        }
        return channels[index]
    }

    func generateChannels(
        count: Int,
        authorDetails: [String: String] = UserDetails.lukeSkywalker,
        memberDetails: [[String: String]] = [
            UserDetails.lukeSkywalker,
            UserDetails.hanSolo,
            UserDetails.countDooku
        ]
    ) {
        var json = channelList
        guard let sampleChannel = (json[JSONKey.channels] as? [[String: Any]])?.first else { return }
        
        let userSources = TestData.toJson(.httpChatEvent)[JSONKey.event] as? [String: Any]
        
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
        
        json[JSONKey.channels] = channels
        channelList = json
    }
    
    private func updateChannelList(_ request: HttpRequest) -> HttpResponse {
        var json = channelList
        guard let id = request.params[EndpointQuery.channelId] else { return .ok(.json(json)) }
        
        var channels = json[JSONKey.channels] as? [[String: Any]]
        if let index = channels?.firstIndex(where: {
            let channel = $0[ChannelPayload.CodingKeys.channel.rawValue] as? [String: Any]
            return (channel?[ChannelCodingKeys.id.rawValue] as? String) == id
        }) {
            let messageList = findMessagesByChannelId(id)
            channels?[index][ChannelPayload.CodingKeys.messages.rawValue] = messageList
            json[JSONKey.channels] = channels
            currentChannelId = id
            channelList = json
        }
        
        return .ok(.json(json))
    }

    // MARK: Channel Members
    private func handleChannelRequest(_ request: HttpRequest) -> HttpResponse? {
        guard let type = ChannelRequestType.type(from: request.body) else {
            print("Unhandled request: \(request)")
            return .badRequest(nil)
        }

        return updateChannelMembers(request, ids: type.ids, eventType: type.eventType)
    }

    private func updateChannelMembers(_ request: HttpRequest,
                                      ids: [String],
                                      eventType: EventType) -> HttpResponse {
        guard
            let id = request.params[EndpointQuery.channelId]
        else {
            return .ok(.json(channelList))
        }

        var json = channelList
        guard
            var channels = json[JSONKey.channels] as? [[String: Any]],
            let channelIndex = channelIndex(withId: id),
            var channel = channel(withId: id),
            var innerChannel = channel[JSONKey.channel] as? [String: Any],
            var members = channel[ChannelCodingKeys.members.rawValue] as? [[String: Any]]
        else {
            return .badRequest(nil)
        }

        let membersWithIds = memberJSONs(for: ids)
        switch eventType {
        case .memberAdded:
            members.append(contentsOf: membersWithIds)
        case .memberRemoved:
            members.removeAll(where: {
                let memberId = $0[JSONKey.userId] as? String
                return ids.contains(memberId ?? "")
            })
        default:
            return .badRequest(nil)
        }
        innerChannel[ChannelCodingKeys.members.rawValue] = members
        innerChannel[ChannelCodingKeys.memberCount.rawValue] = members.count
        channel[JSONKey.channel] = innerChannel
        channels[channelIndex] = channel
        json[JSONKey.channels] = channels

        if let channelId = (channel[JSONKey.channel] as? [String: Any])?[JSONKey.id] as? String {
            // Send web socket event with given event type
            membersWithIds.forEach {
                websocketMember(with: $0, channelId: channelId, eventType: eventType)
            }

            // Send channel update web socket event
            websocketChannelUpdated(with: members, channelId: channelId)
        }

        channelList = json

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
            sampleMember[JSONKey.user] = setUpUser(source: userSources, details: member)
            sampleMember[JSONKey.userId] = member[UserPayloadsCodingKeys.id.rawValue]
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
        membership?[JSONKey.user] = author
        
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
