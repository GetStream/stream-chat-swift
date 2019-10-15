//
//  UIDevice+Extensions.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 19/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIDevice {
    enum ScreenSize {
        case unknown
        case inches4
        case inches47
        case inches55
        case inches58
        case inches61
        case inches65
    }
    
    static let isPhone = UIDevice.current.userInterfaceIdiom == .phone
    static let isPad = UIDevice.current.userInterfaceIdiom == .pad
    
    var phoneScreenSize: ScreenSize {
        guard userInterfaceIdiom == .phone else {
            return .unknown
        }
        
        switch UIScreen.main.nativeBounds.height {
        case 1136:
            return .inches4
        case 1334:
            return .inches47
        case 2208:
            return .inches55
        case 2436:
            return .inches58
        case 1792:
            return .inches61
        case 2688:
            return .inches65
        default:
            return .unknown
        }
    }
    
    var hasBigScreen: Bool {
        return userInterfaceIdiom != .phone
            || phoneScreenSize == .inches55
            || phoneScreenSize == .inches61
            || phoneScreenSize == .inches65
    }
}
