//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryChannelsRequest: Sendable, Encodable, JSONEncodable {
    /// Filter conditions to apply to the query
    let filterConditions: (any Encodable & Sendable)?
    /// Values to interpolate into the predefined filter template
    let filterValues: [String: RawJSON]?
    /// Number of channels to limit
    let limit: Int?
    /// Top-level keys of the message sender's channel-member custom data to include under member.custom (max 8 keys, 64 chars each)
    let memberCustomInclude: [String]?
    /// Number of members to limit
    let memberLimit: Int?
    /// Number of messages to limit
    let messageLimit: Int?
    /// Channel pagination offset
    let offset: Int?
    /// ID of a predefined filter to use instead of filter_conditions
    let predefinedFilter: String?
    let presence: Bool?
    /// List of sort parameters
    let sort: [SortParamRequest]?
    let sortValues: [String: RawJSON]?
    /// Whether to update channel state or not
    let state: Bool?
    /// Whether to start watching found channels or not
    let watch: Bool?

    init(
        filterConditions: (any Encodable & Sendable)? = nil,
        filterValues: [String: RawJSON]? = nil,
        limit: Int? = nil,
        memberCustomInclude: [String]? = nil,
        memberLimit: Int? = nil,
        messageLimit: Int? = nil,
        offset: Int? = nil,
        predefinedFilter: String? = nil,
        presence: Bool? = nil,
        sort: [SortParamRequest]? = nil,
        sortValues: [String: RawJSON]? = nil,
        state: Bool? = nil,
        watch: Bool? = nil
    ) {
        self.filterConditions = filterConditions
        self.filterValues = filterValues
        self.limit = limit
        self.memberCustomInclude = memberCustomInclude
        self.memberLimit = memberLimit
        self.messageLimit = messageLimit
        self.offset = offset
        self.predefinedFilter = predefinedFilter
        self.presence = presence
        self.sort = sort
        self.sortValues = sortValues
        self.state = state
        self.watch = watch
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case filterConditions = "filter_conditions"
        case filterValues = "filter_values"
        case limit
        case memberCustomInclude = "member_custom_include"
        case memberLimit = "member_limit"
        case messageLimit = "message_limit"
        case offset
        case predefinedFilter = "predefined_filter"
        case presence
        case sort
        case sortValues = "sort_values"
        case state
        case watch
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let filterConditions {
            try container.encode(filterConditions, forKey: .filterConditions)
        }
        try container.encodeIfPresent(filterValues, forKey: .filterValues)
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(memberCustomInclude, forKey: .memberCustomInclude)
        try container.encodeIfPresent(memberLimit, forKey: .memberLimit)
        try container.encodeIfPresent(messageLimit, forKey: .messageLimit)
        try container.encodeIfPresent(offset, forKey: .offset)
        try container.encodeIfPresent(predefinedFilter, forKey: .predefinedFilter)
        try container.encodeIfPresent(presence, forKey: .presence)
        try container.encodeIfPresent(sort, forKey: .sort)
        try container.encodeIfPresent(sortValues, forKey: .sortValues)
        try container.encodeIfPresent(state, forKey: .state)
        try container.encodeIfPresent(watch, forKey: .watch)
    }
}
