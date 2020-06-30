//
// MemberEndpoints.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

struct MemberPayload<ExtraData: UserExtraData>: Decodable {
    let roleRawValue: String?
    let created: Date
    let updated: Date
    
    let user: UserPayload<ExtraData>
    
    private enum CodingKeys: String, CodingKey {
        case roleRawValue = "role"
        case created = "created_at"
        case updated = "updated_at"
        case user
    }
    
    internal init(roleRawValue: String, created: Date, updated: Date, user: UserPayload<ExtraData>) {
        self.roleRawValue = roleRawValue
        self.created = created
        self.updated = updated
        self.user = user
    }
}
