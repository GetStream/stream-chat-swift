//
//  RealmObjectIndexable.swift
//  StreamChatRealm
//
//  Created by Alexey Bukhtin on 28/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol RealmObjectIndexable: class {
    static var indexedPropertiesKeyPaths: [AnyKeyPath] { get }
}

extension RealmObjectIndexable {
    public static func indexedProperties() -> [String] {
        return indexedPropertiesKeyPaths.compactMap({ $0._kvcKeyPathString })
    }
}
