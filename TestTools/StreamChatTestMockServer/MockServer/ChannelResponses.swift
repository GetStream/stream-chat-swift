//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import XCTest

public let channelKey = ChannelCodingKeys.self
public let channelPayloadKey = ChannelPayload.CodingKeys.self

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
            let channelId = try XCTUnwrap(request.params[EndpointQuery.channelId])
            self?.channelQueryEndpointWasCalled = true
            self?.updateChannel(withId: channelId)
            return self?.limitQuery(request)
        }
        server.register(MockEndpoint.channels) { [weak self] request in
            self?.channelsEndpointWasCalled = true
            self?.updateChannels()
            return self?.limitChannels(request)
        }
        server.register(MockEndpoint.channel) { [weak self] request in
            self?.handleChannelRequest(request)
        }
        server.register(MockEndpoint.truncate) { [weak self] request in
            self?.channelTruncation(request)
        }
    }

    func channelIndex(withId id: String) -> Int? {
        guard
            let channels = channelList[JSONKey.channels] as? [[String: Any]],
            let index = channels.firstIndex(
                where: {
                    let channel = $0[channelPayloadKey.channel.rawValue] as? [String: Any]
                    return (channel?[channelKey.id.rawValue] as? String) == id
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
    
    func waitForChannelQueryUpdate(timeout: Double = StreamMockServer.waitTimeout) {
        let endTime = Date().timeIntervalSince1970 * 1000 + timeout * 1000
        while !channelQueryEndpointWasCalled
                && endTime > Date().timeIntervalSince1970 * 1000 {}
    }
    
    func waitForChannelsUpdate(timeout: Double = StreamMockServer.waitTimeout) {
        let endTime = Date().timeIntervalSince1970 * 1000 + timeout * 1000
        while !channelsEndpointWasCalled
                && endTime > Date().timeIntervalSince1970 * 1000 {}
    }
    
    private func updateChannel(withId id: String) {
        var json = channelList
        var channels = json[JSONKey.channels] as? [[String: Any]]
        if let index = channels?.firstIndex(where: {
            let channel = $0[channelPayloadKey.channel.rawValue] as? [String: Any]
            return (channel?[channelKey.id.rawValue] as? String) == id
        }) {
            let messageList = findMessagesByChannelId(id)
            if
                var channel = channels?[index],
                var innerChannel = channel[JSONKey.channel] as? [String: Any] {
                setCooldown(in: &innerChannel)
                channel[JSONKey.channel] = innerChannel

                channel[channelPayloadKey.messages.rawValue] = messageList

                channels?[index] = channel
                json[JSONKey.channels] = channels
            }
            currentChannelId = id
            channelList = json
        }
    }
    
    private func updateChannels() {
        var json = channelList
        guard var channels = json[JSONKey.channels] as? [[String: Any]] else { return }
        
        for (index, channel) in channels.enumerated() {
            let channelDetails = channel[channelPayloadKey.channel.rawValue] as? [String: Any]
            if let channelId = channelDetails?[channelKey.id.rawValue] as? String {
                let messageList = findMessagesByChannelId(channelId)
                var mockedChannel = channel
                mockedChannel[channelPayloadKey.messages.rawValue] = messageList
                channels[index] = mockedChannel
            }
        }
        json[JSONKey.channels] = channels
        channelList = json
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
        
        if !allChannelsWereLoaded && channelCount > limit {
            allChannelsWereLoaded = (channelCount - limit - offset < 0)
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
        
        if let idLt = messages?[PaginationParameter.CodingKeys.lessThan.rawValue] {
            let messageIndex = messageList.firstIndex {
                idLt as? String == $0[messageKey.id.rawValue] as? String
            }
            if let messageIndex = messageIndex {
                let startWith = messageIndex - limit > 0 ? messageIndex - limit : 0
                let endWith = messageIndex - 1 > 0 ? messageIndex - 1 : 0
                messageList = Array(messageList[startWith...endWith])
            }
        } else if let idGt = messages?[PaginationParameter.CodingKeys.greaterThan.rawValue] {
            let messageIndex = messageList.firstIndex {
                idGt as? String == $0[messageKey.id.rawValue] as? String
            }
            if let messageIndex = messageIndex {
                let messageCount = messageList.count - 1
                let plusLimit = messageIndex + limit
                let endWith = plusLimit < messageCount ? plusLimit : messageCount
                messageList = Array(messageList[messageIndex + 1...endWith])
            }
        } else if let idLte = messages?[PaginationParameter.CodingKeys.lessThanOrEqual.rawValue] {
            let messageIndex = messageList.firstIndex {
                idLte as? String == $0[messageKey.id.rawValue] as? String
            }
            if let messageIndex = messageIndex {
                let minusLimit = messageIndex - limit
                let startWith = minusLimit > 0 ? minusLimit : 0
                messageList = Array(messageList[startWith + 1...messageIndex])
            }
        } else if let idGte = messages?[PaginationParameter.CodingKeys.greaterThanOrEqual.rawValue] {
            let messageIndex = messageList.firstIndex {
                idGte as? String == $0[messageKey.id.rawValue] as? String
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
        
        channel[channelPayloadKey.messages.rawValue] = messageList
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
            var members = channel[channelKey.members.rawValue] as? [[String: Any]]
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
        innerChannel[channelKey.members.rawValue] = members
        innerChannel[channelKey.memberCount.rawValue] = members.count
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
        let channelMembers = sampleChannel[channelPayloadKey.members.rawValue] as? [[String: Any]]
        guard var sampleMember = channelMembers?.first else { return members }
        
        for member in memberDetails {
            sampleMember[JSONKey.user] = setUpUser(source: userSources, details: member)
            sampleMember[JSONKey.userId] = member[userKey.id.rawValue]
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
        
        var membership = sampleChannel[channelPayloadKey.membership.rawValue] as? [String: Any]
        membership?[JSONKey.user] = author
        
        for channelIndex in 1...count {
            var newChannel = sampleChannel
            var messages: [[String: Any]?] = []
            newChannel[channelPayloadKey.members.rawValue] = members
            newChannel[channelPayloadKey.membership.rawValue] = membership
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
                        channelId: channelDetails?[channelKey.id.rawValue] as? String,
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
            
            newChannel[channelPayloadKey.messages.rawValue] = messages
            newChannel[channelPayloadKey.channel.rawValue] = channelDetails
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
        var channelDetails = channel[channelPayloadKey.channel.rawValue] as? [String: Any]
        let uniqueId = TestData.uniqueId
        let timeInterval = TimeInterval(123_456_789 - channelIndex * 1000)
        let timestamp = TestData.stringTimestamp(Date(timeIntervalSinceNow: timeInterval))
        channelDetails?[channelKey.name.rawValue] = "\(channelIndex)"
        channelDetails?[channelKey.id.rawValue] = uniqueId
        channelDetails?[channelKey.cid.rawValue] = "\(ChannelType.messaging.rawValue):\(uniqueId)"
        channelDetails?[channelKey.createdBy.rawValue] = author
        channelDetails?[channelKey.memberCount.rawValue] = memberCount
        channelDetails?[channelKey.createdAt.rawValue] = timestamp
        channelDetails?[channelKey.updatedAt.rawValue] = timestamp
        return channelDetails
    }
    
    private func findChannelById(_ id: String) -> [String: Any]? {
        try? XCTUnwrap(waitForChannelWithId(id))
    }
    
    func removeChannel(_ id: String) {
        let deletedChannel = try? XCTUnwrap(findChannelById(id))
        guard var channels = channelList[JSONKey.channels] as? [[String: Any]] else { return }
        
        if let deletedIndex = channels.firstIndex(where: { (channel) -> Bool in
            (channel[channelKey.id.rawValue] as? String) == (deletedChannel?[channelKey.id.rawValue] as? String)
        }) {
            channels.remove(at: deletedIndex)
        }
        
        channelList[JSONKey.channels] = channels
    }
    
    private func truncateChannel(_ id: String, truncatedAt: String, truncatedBy: [String: Any]?) {
        let channelMessages = findMessagesByChannelId(id)
        for message in channelMessages {
            removeMessage(message)
        }
        
        var channel = findChannelById(id)
        var channelDetails = channel?[JSONKey.channel] as? [String: Any]
        channelDetails?[JSONKey.Channel.truncatedBy] = truncatedBy
        channelDetails?[channelKey.truncatedAt.rawValue] = truncatedAt
        
        channel?[JSONKey.channel] = channelDetails
        channel?[JSONKey.messages] = []
        
        if var channels = channelList[JSONKey.channels] as? [[String: Any]?] {
            removeChannel(id)
            channels.append(channel)
            channelList[JSONKey.channels] = channels
        }
    }
    
    private func waitForChannelWithId(_ id: String) -> [String: Any]? {
        let endTime = TestData.waitingEndTime
        var newChannelList: [[String: Any]] = []
        while newChannelList.isEmpty && endTime > TestData.currentTimeInterval {
            guard let channels = channelList[JSONKey.channels] as? [[String: Any]] else { return nil }
            newChannelList = channels.filter {
                let channel = $0[JSONKey.channel] as? [String: Any]
                return id == channel?[channelKey.id.rawValue] as? String
            }
        }
        return newChannelList.first
    }
    
    private func channelTruncation(_ request: HttpRequest) -> HttpResponse? {
        waitForChannelQueryUpdate()
        guard let channelId = request.params[EndpointQuery.channelId] else { return .badRequest(nil) }
        var json = TestData.toJson(.httpTruncate)
        var truncatedMessage: [String: Any]?
        var channel = json[JSONKey.channel] as? [String: Any]
        let channelDetails = findChannelById(channelId)?[JSONKey.channel] as? [String: Any]
        let truncatedby = channelDetails?[channelKey.createdBy.rawValue] as? [String: Any]
        let truncatedAt = TestData.currentDate
        
        truncateChannel(
            channelId,
            truncatedAt: truncatedAt,
            truncatedBy: truncatedby
        )
        
        channel?[channelKey.id.rawValue] = channelId
        channel?[channelKey.cid.rawValue] = "\(ChannelType.messaging.rawValue):\(channelId)"
        channel?[JSONKey.Channel.truncatedBy] = truncatedby
        channel?[channelKey.truncatedAt.rawValue] = truncatedAt
        channel?[channelKey.name.rawValue] = channelDetails?[channelKey.name.rawValue]
        
        websocketEvent(
            .channelTruncated,
            user: truncatedby,
            channelId: channelId,
            channel: channel
        )
        
        if let message = TestData.toJson(request.body)[JSONKey.message] as? [String: Any] {
            truncatedMessage = json[JSONKey.message] as? [String: Any]
            truncatedMessage?[messageKey.id.rawValue] = message[messageKey.id.rawValue]
            if let text = message[messageKey.text.rawValue] as? String {
                truncatedMessage?[messageKey.text.rawValue] = text
                truncatedMessage?[messageKey.html.rawValue] = text.html
            }
            websocketMessage(
                truncatedMessage?[messageKey.text.rawValue] as? String,
                channelId: channelId,
                messageId: truncatedMessage?[messageKey.id.rawValue] as? String,
                messageType: .system,
                eventType: .messageNew,
                user: truncatedby,
                channel: channel
            )
        } else {
            truncatedMessage = nil
        }
        
        json[JSONKey.message] = truncatedMessage
        json[JSONKey.channel] = channel
        return .ok(.json(json))
    }
}
