//
//  Bundle+Extensions.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 19/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

extension Bundle {
    enum InfoKey: String {
        case photo = "NSPhotoLibraryUsageDescription"
        case camera = "NSCameraUsageDescription"
        case microphone = "NSMicrophoneUsageDescription"
    }
    
    func hasInfoDescription(for key: InfoKey) -> Bool {
        if let info = infoDictionary?[key.rawValue] as? String {
            return !info.isEmpty
        }
        
        return false
    }
}
