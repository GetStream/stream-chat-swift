//
//  ContactModel.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 09/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

struct ContactModel: Codable, Equatable, Hashable {
    var name: String
    var username: String?
    var walletAddress: String
    var avatar: String?
    var created: Date
    var updated: Date
}

struct ContactSectionData: Hashable {
    var sectionName: String
    var data: [ContactModel]
}
