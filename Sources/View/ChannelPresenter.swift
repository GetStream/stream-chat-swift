//
//  ChannelPresenter.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public final class ChannelPresenter {
    public private(set) var channel: Channel
    var members: [User] = []
    var messages: [Message] = []
    
    init(channel: Channel) {
        self.channel = channel
        load()
    }
}

// MARK: - Update Channel

extension ChannelPresenter {
    func load() {
        guard let user = Client.shared.user else {
            return
        }
        
        channel.create(members: [user]) { [weak self] in self?.parseQuery($0) }
    }
    
    private func parseQuery(_ result: Result<Query, ClientError>) {
        do {
            let query = try result.get()
            channel = query.channel
            members = query.members
            messages = query.messages
        } catch {
            print(result)
        }
    }
}
