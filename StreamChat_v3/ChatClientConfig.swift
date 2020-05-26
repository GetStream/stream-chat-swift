//
//  ChatClientConfig.swift
//  StreamChat_v3
//
//  Created by Vojta on 26/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

extension ChatClient {
    public struct Config {
        
        /// The folder ChatClient uses to store its database files.
        public var localStorageFolderURL: URL = {
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            
        }()
        
        public var channel = Channel()
        
    }
}

extension ChatClient.Config {
    public struct Channel {
        public var isReplyInChannelAllowed = true
    }
    
    public struct Message {
        // something
    }

}
