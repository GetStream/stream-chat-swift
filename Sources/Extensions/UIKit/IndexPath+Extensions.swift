//
//  IndexPath+Extensions.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 06/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension IndexPath {
    
    static func row(_ row: Int) -> IndexPath {
        return IndexPath(row: row, section: 0)
    }
    
    static func item(_ item: Int) -> IndexPath {
        return IndexPath(item: item, section: 0)
    }
}
