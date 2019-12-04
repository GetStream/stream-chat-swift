//
//  Data+Extensions.swift
//  StreamChatRealm
//
//  Created by Alexey Bukhtin on 28/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import KeychainAccess

extension Data {
    static func encryptionKey(userKey: String) throws -> Data {
        if let keyData = try RealmDatabase.keychain.getData(userKey) {
            return keyData
        }
        
        if let key = NSMutableData(length: 64) {
            _ = SecRandomCopyBytes(kSecRandomDefault, key.length, UnsafeMutableRawPointer(key.mutableBytes))
            
            if let keyData = key.copy() as? Data {
                try RealmDatabase.keychain.set(keyData, key: userKey)
                
                return keyData
            }
        }
        
        throw RealmDatabase.Error.generatingKeyDataFailed
    }
}
