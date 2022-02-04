//
//  Snackbar.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 26/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

class Snackbar {
    static func show(text: String) {
        var userInfo = [String: Any]()
        userInfo["message"] = text
        NotificationCenter.default.post(name: .showSnackBar, object: nil, userInfo: userInfo)
    }
}
