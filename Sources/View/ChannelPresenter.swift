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
    }
}

// MARK: - Update Channel

extension ChannelPresenter {
    func load(_ completion: @escaping () -> Void) {
        guard let user = Client.shared.user else {
            return
        }
        
        channel.create(members: [user]) { [weak self] in self?.parseQuery($0, completion) }
    }
    
    private func parseQuery(_ result: Result<Query, ClientError>, _ completion: @escaping () -> Void) {
        do {
            let query = try result.get()
            channel = query.channel
            members = query.members
            messages = query.messages
        } catch let clientError as ClientError {
            print(clientError)
        } catch {
            print(error)
        }
        
        completion()
    }
}
