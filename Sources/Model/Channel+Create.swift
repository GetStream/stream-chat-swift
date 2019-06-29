//
//  Channel+Create.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 07/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Create

public extension Channel {
    
    static func create(type: ChannelType = .messaging,
                id: String = "",
                name: String? = nil,
                imageURL: URL? = nil,
                memberIds: [String] = [],
                extraData: Codable? = nil) -> Observable<ChannelQuery> {
        guard let currentUser = Client.shared.user else {
            return .empty()
        }
        
        var memberIds = memberIds
        
        if !memberIds.contains(currentUser.id) {
            memberIds.append(currentUser.id)
        }
        
        let channel = Channel(type: type, id: id, name: name, imageURL: imageURL, memberIds: memberIds, extraData: extraData)
        
        return Client.shared.webSocket.connection.connected()
            .flatMapLatest { _ in Client.shared.rx.request(endpoint: .createChannel(channel)) }
    }
}
