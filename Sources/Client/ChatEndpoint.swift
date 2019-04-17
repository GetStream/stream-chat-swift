//
//  ChatEndpoint.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

enum ChatEndpoint: EndpointProtocol {
    case query(_ query: Query)
    case send(_ message: Message, channel: Channel)
}

extension ChatEndpoint {
    var method: Client.Method {
        return .post
    }
    
    var path: String {
        switch self {
        case .query(let query):
            return path(with: query.channel).appending("query")
        case .send(_, let channel):
            return path(with: channel).appending("message")
        }
    }
    
    var body: Encodable? {
        switch self {
        case .query(let query):
            return query
        case .send(let message, _):
            return ["message": message]
        }
    }
    
    func path(with channel: Channel) -> String {
        return "channels/\(channel.type.rawValue)/\(channel.id)/"
    }
}
