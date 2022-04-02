//
//  SCSettings.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 09/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

enum SCSettings {}

struct SCSettingsItem<Type> {
    var key: String
    var defaultValue: Type
}

extension SCSettings {
    enum Contact {
        static var contactList = SCSettingsItem(key: "contact-list",
                                               defaultValue: Data())
    }
}
