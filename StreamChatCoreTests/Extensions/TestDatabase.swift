//
//  TestDatabase.swift
//  StreamChatCoreTests
//
//  Created by Alexey Bukhtin on 19/09/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift
@testable import StreamChatCore

public final class TestDatabase: Database {
    public var user: User?
    var channelResponses: [ChannelResponse] = []
    var channelResponsePage1: ChannelResponse?
    var channelResponsePage2: ChannelResponse?
    
    public func channels(_ query: ChannelsQuery) -> Observable<[ChannelResponse]> {
        print("🗄🗄🗄 fetch channels", query)
        
        if channelResponses.isEmpty {
            return .empty()
        }
        
        return .just(channelResponses)
    }
    
    public func channel(channelType: ChannelType, channelId: String, pagination: Pagination) -> Observable<ChannelResponse> {
        print("🗄 fetch channel:", channelType, channelId, pagination)
        
        if let channelResponse = channelResponsePage1 {
            return .just(pagination == Pagination.messagesPageSize
                ? channelResponse
                : ChannelResponse(channel: channelResponse.channel))
        }
        
        return .empty()
    }
    
    public func add(channelResponses: [ChannelResponse]) {
        if channelResponses.isEmpty || channelResponsePage1 != nil {
            return
        }
        
        print("🗄 added, responses: ", channelResponses.count, "first channel messages:", channelResponses[0].messages.count)
        
        if let channelResponse = channelResponses.first, channelResponses.count == 1 {
            if channelResponsePage1 == nil {
                channelResponsePage1 = channelResponse
            } else if channelResponsePage2 == nil {
                channelResponsePage2 = channelResponse
            }
        }
        
        if !channelResponses.isEmpty {
            self.channelResponses = channelResponses
        }
    }
    
    public init() {}
}
