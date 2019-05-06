//
//  IndexPath+Extensions.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 06/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension IndexPath {
    
    init(row: Int) {
        self.init(row: row, section: 0)
    }
    
    init(item: Int) {
        self.init(item: item, section: 0)
    }
}
