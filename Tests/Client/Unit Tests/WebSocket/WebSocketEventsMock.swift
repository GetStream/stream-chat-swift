//
//  WebSocketEventsMock.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 03/06/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

extension Dictionary {
    
    /// Helper function to create a `health.check` event JSON with the given `userId` and `connectId`.
    static func healthCheckEvent(userId: String, connectionId: String) -> [String: Any] {
        [
            "created_at" : "2020-05-02T13:21:03.862065063Z",
            "me" : [
                "id" : userId,
                "banned" : false,
                "unread_channels" : 0,
                "mutes" : [],
                "last_active" : "2020-05-02T13:21:03.849219Z",
                "created_at" : "2019-06-05T15:01:52.847807Z",
                "devices" : [],
                "invisible" : false,
                "unread_count" : 0,
                "channel_mutes" : [],
                "image" : "https://i.imgur.com/EgEPqWZ.jpg",
                "updated_at" : "2020-05-02T13:21:03.855468Z",
                "role" : "user",
                "total_unread_count" : 0,
                "online" : true,
                "name" : "Steep Moon",
                "test" : 1
            ],
            "type" : "health.check",
            "connection_id" : connectionId
        ]
    }
    
    static func typingStartEvent(userId: String) -> [String: Any] {
        [
            "type": "typing.start",
            "user": [
                "id": "\(userId)",
                "role": "user",
                "created_at": "2020-05-12T12:42:56.450979Z",
                "updated_at": "2020-05-12T12:42:56.450979Z",
                "online": true
            ]
        ]
    }
}
