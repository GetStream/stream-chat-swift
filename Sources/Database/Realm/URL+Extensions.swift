//
//  URL+Extensions.swift
//  StreamChatRealm
//
//  Created by Alexey Bukhtin on 28/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

extension URL {
    private static let baseSubFolder = "StreamChatRealm"
    
    @discardableResult
    static func baseRealmURL(_ basePath: RealmDatabase.BasePath, subPath: String? = nil) throws -> URL {
        guard let path = basePath.path else {
            throw RealmDatabase.Error.documentsPathFailed
        }
        
        var realmURL = URL(fileURLWithPath: path).appendingPathComponent(URL.baseSubFolder)
        
        if let subPath = subPath {
            realmURL.appendPathComponent(subPath)
        }
        
        if !FileManager.default.fileExists(atPath: realmURL.path) {
            try FileManager.default.createDirectory(at: realmURL, withIntermediateDirectories: true)
            
            if case .caches = basePath {} else {
                realmURL.excludeFromBackup()
            }
        }
        
        return realmURL
    }
    
    func excludeFromBackup() {
        var url = self
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try? url.setResourceValues(resourceValues)
    }
}
