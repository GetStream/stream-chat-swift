//
//  UIImagePickerController+Extensions.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 19/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIImagePickerController {
    
    static func hasPermissionDescription(for sourceType: UIImagePickerController.SourceType) -> Bool {
        switch sourceType {
        case .savedPhotosAlbum, .photoLibrary:
            return Bundle.main.hasInfoDescription(for: .photo)
        case .camera:
            return Bundle.main.hasInfoDescription(for: .camera)
        @unknown default:
            return false
        }
    }
}
