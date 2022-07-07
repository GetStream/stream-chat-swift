//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import XCTest

public extension StreamMockServer {

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
            self?.channelQueryEndpointWasCalled = true
            self?.updateChannelList(request)
            return self?.limitQuery(request)
        }
        server.register(MockEndpoint.channels) { [weak self] request in
            self?.channelsEndpointWasCalled = true
            return self?.limitChannels(request)
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
    
    func waitForChannelQueryUpdate(timeout: Double = XCUIElement.waitTimeout) {
        let endTime = Date().timeIntervalSince1970 * 1000 + timeout * 1000
        while !channelQueryEndpointWasCalled
                && endTime > Date().timeIntervalSince1970 * 1000 {}
    }
    
    func waitForChannelsUpdate(timeout: Double = XCUIElement.waitTimeout) {
        let endTime = Date().timeIntervalSince1970 * 1000 + timeout * 1000
        while !channelsEndpointWasCalled
                && endTime > Date().timeIntervalSince1970 * 1000 {}
    }
    
    private func updateChannelList(_ request: HttpRequest) {
        var json = channelList
        guard let id = request.params[EndpointQuery.channelId] else { return }

        var channels = json[JSONKey.channels] as? [[String: Any]]
        if let index = channels?.firstIndex(where: {
            let channel = $0[ChannelPayload.CodingKeys.channel.rawValue] as? [String: Any]
            return (channel?[ChannelCodingKeys.id.rawValue] as? String) == id
        }) {
            let messageList = findMessagesByChannelId(id)
            if
                var channel = channels?[index],
                var innerChannel = channel[JSONKey.channel] as? [String: Any] {
                setCooldown(in: &innerChannel)
                channel[JSONKey.channel] = innerChannel

                channel[ChannelPayload.CodingKeys.messages.rawValue] = messageList

                channels?[index] = channel
                json[JSONKey.channels] = channels
            }
            currentChannelId = id
            channelList = json
        }
    }
    
    private func limitChannels(_ request: HttpRequest) -> HttpResponse {
        guard
            let payloadQuery = request.queryParams.first(where: { $0.0 == JSONKey.payload }),
            let payload = payloadQuery.1.removingPercentEncoding?.json,
            let limit = payload[Pagination.CodingKeys.pageSize.rawValue] as? Int
        else {
            return .ok(.json(channelList))
        }
        
        let offset = payload[Pagination.CodingKeys.offset.rawValue] as? Int ?? 0
        
        var limitedChannelList = channelList
        let channels = limitedChannelList[JSONKey.channels] as? [[String: Any]] ?? []
        let channelCount = channels.count - 1
        
        if channelCount > limit {
            let startWith = offset > channelCount ? channelCount : offset
            let endWith = offset + limit < channelCount ? offset + limit - 1 : channelCount
            limitedChannelList[JSONKey.channels] = Array(channels[startWith...endWith])
        }
        
        return .ok(.json(limitedChannelList))
    }
    
    private func limitQuery(_ request: HttpRequest) -> HttpResponse {
        let json = TestData.toJson(request.body)
        let messages = json[JSONKey.messages] as? [String: Any]
        
        guard let id = request.params[EndpointQuery.channelId] else { return .badRequest(nil) }
        guard var channel = findChannelById(id) else { return .badRequest(nil) }
        guard let limit = messages?[MessagesPagination.CodingKeys.pageSize.rawValue] as? Int else {
            return .ok(.json(channel))
        }
        var messageList = findMessagesByChannelId(id)
        let idKey = MessagePayloadsCodingKeys.id.rawValue
        
        if let idLt = messages?[PaginationParameter.CodingKeys.lessThan.rawValue] {
            let messageIndex = messageList.firstIndex {
                idLt as? String == $0[idKey] as? String
            }
            if let messageIndex = messageIndex {
                let startWith = messageIndex - limit > 0 ? messageIndex - limit : 0
                let endWith = messageIndex - 1 > 0 ? messageIndex - 1 : 0
                messageList = Array(messageList[startWith...endWith])
            }
        } else if let idGt = messages?[PaginationParameter.CodingKeys.greaterThan.rawValue] {
            let messageIndex = messageList.firstIndex {
                idGt as? String == $0[idKey] as? String
            }
            if let messageIndex = messageIndex {
                let messageCount = messageList.count - 1
                let plusLimit = messageIndex + limit
                let endWith = plusLimit < messageCount ? plusLimit : messageCount
                messageList = Array(messageList[messageIndex + 1...endWith])
            }
        } else if let idLte = messages?[PaginationParameter.CodingKeys.lessThanOrEqual.rawValue] {
            let messageIndex = messageList.firstIndex {
                idLte as? String == $0[idKey] as? String
            }
            if let messageIndex = messageIndex {
                let minusLimit = messageIndex - limit
                let startWith = minusLimit > 0 ? minusLimit : 0
                messageList = Array(messageList[startWith + 1...messageIndex])
            }
        } else if let idGte = messages?[PaginationParameter.CodingKeys.greaterThanOrEqual.rawValue] {
            let messageIndex = messageList.firstIndex {
                idGte as? String == $0[idKey] as? String
            }
            if let messageIndex = messageIndex {
                let messageCount = messageList.count - 1
                let plusLimit = messageIndex + limit
                let endWith = plusLimit < messageCount ? plusLimit - 1 : messageCount
                messageList = Array(messageList[messageIndex...endWith])
            }
        } else {
            messageList = Array(messageList.suffix(limit))
        }
        
        channel[ChannelPayload.CodingKeys.messages.rawValue] = messageList
        return .ok(.json(channel))
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
        setCooldown(in: &innerChannel)
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

    func mockMembers(
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
    
    func mockChannels(
        count: Int,
        messagesCount: Int,
        author: [String: Any]?,
        members: [[String: Any]],
        sampleChannel: [String: Any]
    ) -> [[String: Any]] {
        var channels: [[String: Any]] = []
        guard count > 0 else { return channels }
        
        var membership = sampleChannel[ChannelPayload.CodingKeys.membership.rawValue] as? [String: Any]
        membership?[JSONKey.user] = author
        
        for channelIndex in 1...count {
            var newChannel = sampleChannel
            var messages: [[String: Any]?] = []
            newChannel[ChannelPayload.CodingKeys.members.rawValue] = members
            newChannel[ChannelPayload.CodingKeys.membership.rawValue] = membership
            let channelDetails = mockChannelDetails(
                channel: newChannel,
                author: author,
                memberCount: members.count,
                channelIndex: channelIndex
            )
            
            if messagesCount > 0 {
                for messageIndex in 1...messagesCount {
                    let timeInterval = TimeInterval(messageIndex * 1000 - 123_456_789)
                    let timestamp = TestData.stringTimestamp(Date(timeIntervalSinceNow: timeInterval))
                    let message = mockMessage(
                        TestData.toJson(.message)[JSONKey.message] as? [String : Any],
                        channelId: channelDetails?[ChannelCodingKeys.id.rawValue] as? String,
                        messageId: TestData.uniqueId,
                        text: String(messageIndex),
                        user: author,
                        createdAt: timestamp,
                        updatedAt: timestamp
                    )
                    messages.append(message)
                    saveMessage(message)
                }
            }
            
            newChannel[ChannelPayload.CodingKeys.messages.rawValue] = messages
            newChannel[ChannelPayload.CodingKeys.channel.rawValue] = channelDetails
            channels.append(newChannel)
        }
        
        return channels
    }
    
    private func mockChannelDetails(
        channel: [String: Any],
        author: [String: Any]?,
        memberCount: Int,
        channelIndex: Int
    ) -> [String: Any]? {
        var channelDetails = channel[ChannelPayload.CodingKeys.channel.rawValue] as? [String: Any]
        let uniqueId = TestData.uniqueId
        let timeInterval = TimeInterval(123_456_789 - channelIndex * 1000)
        let timestamp = TestData.stringTimestamp(Date(timeIntervalSinceNow: timeInterval))
        channelDetails?[ChannelCodingKeys.name.rawValue] = "\(channelIndex)"
        channelDetails?[ChannelCodingKeys.id.rawValue] = uniqueId
        channelDetails?[ChannelCodingKeys.cid.rawValue] = "\(ChannelType.messaging.rawValue):\(uniqueId)"
        channelDetails?[ChannelCodingKeys.createdBy.rawValue] = author
        channelDetails?[ChannelCodingKeys.memberCount.rawValue] = memberCount
        channelDetails?[ChannelCodingKeys.createdAt.rawValue] = timestamp
        channelDetails?[ChannelCodingKeys.updatedAt.rawValue] = timestamp
        return channelDetails
    }
    
    private func findChannelById(_ id: String) -> [String: Any]? {
        try? XCTUnwrap(waitForChannelWithId(id))
    }
    
    private func waitForChannelWithId(_ id: String) -> [String: Any]? {
        let endTime = TestData.waitingEndTime
        var newChannelList: [[String: Any]] = []
        while newChannelList.isEmpty && endTime > TestData.currentTimeInterval {
            guard let channels = channelList[JSONKey.channels] as? [[String: Any]] else { return nil }
            newChannelList = channels.filter {
                let channel = $0[JSONKey.channel] as? [String: Any]
                return id == channel?[ChannelCodingKeys.id.rawValue] as? String
            }
        }
        return newChannelList.first
    }
    
}
