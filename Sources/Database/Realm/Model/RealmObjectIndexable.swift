//
//  RealmObjectIndexable.swift
//  StreamChatRealm
//
//  Created by Alexey Bukhtin on 28/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import RealmSwift

extension Object {
    static func indexedPropertiesKeyPaths(_ keyPaths: [AnyKeyPath]) -> [String] {
        return keyPaths.compactMap({ $0._kvcKeyPathString })
    }
}
