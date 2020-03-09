//
//  Bundle+Extensions.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/03/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

extension Bundle {
    
    /// A bundle id.
    public var id: String? {
        infoDictionary?["CFBundleIdentifier"] as? String
    }
    
    /// A bundle name.
    public var name: String? {
        object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
    }
}
