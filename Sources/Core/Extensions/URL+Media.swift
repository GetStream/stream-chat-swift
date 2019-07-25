//
//  URL+Media.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 05/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

extension URL {
    /// Get a file size from the file URL.
    public var fileSize: Int64 {
        if let attr = try? FileManager.default.attributesOfItem(atPath: path),
            let size = attr[FileAttributeKey.size] as? UInt64 {
            return Int64(size)
        }
        
        return 0
    }
}
