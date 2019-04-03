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
}

extension ChatEndpoint {
    var method: Client.Method {
        return .post
    }
    
    var path: String {
        switch self {
        case .query(let query):
            return "channels/\(query.channel.type.rawValue)/\(query.channel.id)/query"
        }
    }
    
    var body: Encodable? {
        switch self {
        case .query(let query):
            return query
        }
    }
}
