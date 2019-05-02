//
//  UIViewController+Extensions.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 02/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIViewController {
    var isVisible: Bool {
        return isViewLoaded && view.window != nil
    }
}
