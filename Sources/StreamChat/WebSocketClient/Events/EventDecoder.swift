//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A lightweight object for decoding incoming events.
struct EventDecoder {
    func decode(from data: Data) throws -> Event {
        let decoder = JSONDecoder.default

        // Peek at the `type` field once. Used to route events that aren't
        // covered by the OpenAPI-generated `WSEvent` enum (connection.error)
        // and to classify unknowns by presence of `cid`.
        let envelope = try? decoder.decode(EventTypeEnvelope.self, from: data)

        if envelope?.type == .connectionError {
            return try decoder.decode(ConnectionErrorEvent.self, from: data)
        }

        // The SDK explicitly ignores `channel.created` regardless of payload
        // validity — short-circuit before attempting a strict decode.
        if envelope?.type == .channelCreated {
            throw ClientError.IgnoredEventType()
        }

        // Backfill commonly-missing-but-required OpenAPI fields with derived
        // defaults so the strict generated DTOs can decode legacy payloads.
        let normalized = Self.normalize(data) ?? data

        // Primary path: WSEvent (OpenAPI union of all known WS events).
        let wsDecodeResult = Result {
            try decoder.decode(WSEvent.self, from: normalized)
        }
        switch wsDecodeResult {
        case .success(let wsEvent):
            let event = try wsEvent.makeEvent()
            storeWSEvent(wsEvent, on: event as AnyObject)
            return event
        case .failure(let decodeError):
            // If the `type` is one the OpenAPI WSEvent enum knows about,
            // surface a decoding error so callers can distinguish a malformed
            // known event from a genuinely-unknown custom event.
            if let type = envelope?.type, Self.knownEventTypes.contains(type.rawValue) {
                throw ClientError.EventDecoding(missingValue: "\(decodeError)", for: type.rawValue)
            }
        }

        // Unknown event type: route by presence of `cid`.
        if envelope?.cid != nil {
            return try decoder.decode(UnknownChannelEvent.self, from: data)
        } else {
            return try decoder.decode(UnknownUserEvent.self, from: data)
        }
    }

    /// Injects default values for fields the legacy `EventPayload` decoder used
    /// to tolerate but the OpenAPI-generated DTOs require. Returns `nil` and
    /// callers should fall back to the raw payload if anything goes wrong.
    static func normalize(_ data: Data) -> Data? {
        guard var dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            return nil
        }
        normalize(dict: &dict)
        return try? JSONSerialization.data(withJSONObject: dict)
    }

    private static func normalize(dict: inout [String: Any]) {
        let type = dict["type"] as? String

        // Derive `message_id` from `message.id` when missing.
        if dict["message_id"] == nil,
           let message = dict["message"] as? [String: Any],
           let id = message["id"] as? String {
            dict["message_id"] = id
        }
        // Derive `user_id` from `user.id` when missing.
        if dict["user_id"] == nil,
           let user = dict["user"] as? [String: Any],
           let id = user["id"] as? String {
            dict["user_id"] = id
        }
        // Derive `thread_id` from `message.parent_id` when missing.
        if dict["thread_id"] == nil,
           let message = dict["message"] as? [String: Any],
           let parentId = message["parent_id"] as? String {
            dict["thread_id"] = parentId
        }
        // Derive `cid` from `reminder.channel_cid` when missing.
        if dict["cid"] == nil,
           let reminder = dict["reminder"] as? [String: Any],
           let channelCid = reminder["channel_cid"] as? String {
            dict["cid"] = channelCid
        }
        // `watcher_count` is required on every message/notification.new event.
        if dict["watcher_count"] == nil {
            dict["watcher_count"] = 0
        }
        // `hard_delete` is required on message.deleted.
        if dict["hard_delete"] == nil {
            dict["hard_delete"] = false
        }
        // `custom` is required on every event DTO.
        if dict["custom"] == nil {
            dict["custom"] = [String: Any]()
        }
        // notification.mark_read requires non-nil `total_unread_count`,
        // `unread_channels`, `unread_count`. Other events keep them as
        // optional so we must not override missing values there.
        // Legacy payloads historically nest these counts inside `user`.
        if type == "notification.mark_read" {
            let user = dict["user"] as? [String: Any]
            if dict["total_unread_count"] == nil {
                dict["total_unread_count"] = user?["total_unread_count"] ?? 0
            }
            if dict["unread_channels"] == nil {
                dict["unread_channels"] = user?["unread_channels"] ?? 0
            }
            if dict["unread_count"] == nil {
                dict["unread_count"] = user?["unread_count"] ?? 0
            }
            if dict["unread_thread_messages"] == nil, let threads = user?["unread_threads"] {
                dict["unread_thread_messages"] = threads
            }
        }
        // Synthesize a minimal `channel` placeholder ONLY for event types
        // that require a non-optional channel — events like
        // `notification.mark_read` rely on `channel == nil` to disambiguate.
        if let type, eventTypesRequiringChannel.contains(type),
           dict["channel"] == nil,
           let cid = dict["cid"] as? String,
           let parsed = parseCid(cid) {
            let createdAt = dict["created_at"] as? String ?? defaultDateString
            dict["channel"] = [
                "cid": cid,
                "id": parsed.id,
                "type": parsed.type,
                "created_at": createdAt,
                "updated_at": createdAt,
                "disabled": false,
                "frozen": false,
                "custom": [:]
            ]
        } else if var channel = dict["channel"] as? [String: Any] {
            // Backfill required channel fields when partially-populated.
            normalizeChannel(channel: &channel, fallbackCreatedAt: dict["created_at"] as? String)
            dict["channel"] = channel
        }
        // Synthesize a minimal `member` placeholder ONLY for event types that
        // require a non-optional member.
        if let type, eventTypesRequiringMember.contains(type),
           dict["member"] == nil,
           let user = dict["user"] as? [String: Any],
           let userId = user["id"] as? String {
            let createdAt = dict["created_at"] as? String ?? defaultDateString
            dict["member"] = [
                "user_id": userId,
                "created_at": createdAt,
                "updated_at": createdAt,
                "banned": false,
                "shadow_banned": false,
                "channel_role": "",
                "notifications_muted": false,
                "custom": [:]
            ]
        }
    }

    /// Event types whose OpenAPI DTOs declare a non-optional `channel` field.
    private static let eventTypesRequiringChannel: Set<String> = [
        "channel.created", "channel.deleted", "channel.hidden", "channel.truncated",
        "channel.updated", "channel.visible",
        "member.added", "member.removed", "member.updated",
        "notification.added_to_channel", "notification.channel_deleted",
        "notification.channel_truncated", "notification.invite_accepted",
        "notification.invited", "notification.invite_rejected",
        "notification.message_new", "notification.removed_from_channel",
        "notification.thread_message_new",
        "reaction.deleted", "reaction.new", "reaction.updated"
    ]

    /// Event types whose OpenAPI DTOs declare a non-optional `member` field.
    private static let eventTypesRequiringMember: Set<String> = [
        "member.added", "member.removed", "member.updated",
        "notification.added_to_channel", "notification.invite_accepted",
        "notification.invited", "notification.invite_rejected",
        "notification.removed_from_channel"
    ]

    /// Event types the OpenAPI-generated `WSEvent` enum can decode. Used by
    /// `decode(from:)` to distinguish a malformed known event from a
    /// genuinely-unknown custom event.
    private static let knownEventTypes: Set<String> = [
        "ai_indicator.clear", "ai_indicator.stop", "ai_indicator.update",
        "app.updated",
        "channel.created", "channel.deleted", "channel.frozen", "channel.hidden",
        "channel.kicked", "channel.max_streak_changed", "channel.truncated",
        "channel.unfrozen", "channel.updated", "channel.visible",
        "draft.deleted", "draft.updated",
        "health.check",
        "member.added", "member.removed", "member.updated",
        "message.deleted", "message.delivered", "message.new", "message.pending",
        "message.read", "message.undeleted", "message.updated",
        "moderation.custom_action", "moderation.flagged", "moderation.mark_reviewed",
        "notification.added_to_channel", "notification.channel_deleted",
        "notification.channel_mutes_updated", "notification.channel_truncated",
        "notification.invite_accepted", "notification.invite_rejected",
        "notification.invited", "notification.mark_read", "notification.mark_unread",
        "notification.message_new", "notification.mutes_updated",
        "notification.reminder_due", "notification.removed_from_channel",
        "notification.thread_message_new",
        "poll.closed", "poll.deleted", "poll.updated", "poll.vote_casted",
        "poll.vote_changed", "poll.vote_removed",
        "reaction.deleted", "reaction.new", "reaction.updated",
        "reminder.created", "reminder.deleted", "reminder.updated",
        "thread.updated",
        "typing.start", "typing.stop",
        "user.banned", "user.deactivated", "user.deleted", "user.messages.deleted",
        "user.muted", "user.presence.changed", "user.reactivated", "user.unbanned",
        "user.updated", "user.watching.start", "user.watching.stop",
        "user_group.created", "user_group.deleted", "user_group.member_added",
        "user_group.member_removed", "user_group.updated"
    ]

    /// Backfills required ChannelResponse fields when the embedded `channel`
    /// object is partially-populated by legacy test fixtures.
    private static func normalizeChannel(channel: inout [String: Any], fallbackCreatedAt: String?) {
        let createdAt = (channel["created_at"] as? String)
            ?? fallbackCreatedAt
            ?? defaultDateString
        if channel["created_at"] == nil { channel["created_at"] = createdAt }
        if channel["updated_at"] == nil { channel["updated_at"] = createdAt }
        if channel["disabled"] == nil { channel["disabled"] = false }
        if channel["frozen"] == nil { channel["frozen"] = false }
        if channel["custom"] == nil { channel["custom"] = [:] }
        // Drop incomplete `config` objects — they require many fields the
        // generated `ChannelConfigWithInfo` insists on. The field itself is
        // optional, so dropping it is preferable to a decode failure.
        if let config = channel["config"] as? [String: Any], config["created_at"] == nil {
            channel.removeValue(forKey: "config")
        }
        // Backfill required fields on nested member objects.
        if let members = channel["members"] as? [[String: Any]] {
            channel["members"] = members.map { member -> [String: Any] in
                var normalized = member
                normalizeMember(member: &normalized, fallbackCreatedAt: createdAt)
                return normalized
            }
        }
        // Some fixtures omit `cid`/`id`/`type` but provide them at the event level.
        // Nothing to do here — the event-level `channel_type`/`channel_id` aren't
        // copied into the nested object; tests that need that detail provide it.
    }

    /// Backfills required ChannelMemberResponse fields when a member object is
    /// partially-populated.
    private static func normalizeMember(member: inout [String: Any], fallbackCreatedAt: String) {
        if member["created_at"] == nil { member["created_at"] = fallbackCreatedAt }
        if member["updated_at"] == nil { member["updated_at"] = fallbackCreatedAt }
        if member["banned"] == nil { member["banned"] = false }
        if member["shadow_banned"] == nil { member["shadow_banned"] = false }
        if member["channel_role"] == nil { member["channel_role"] = "" }
        if member["notifications_muted"] == nil { member["notifications_muted"] = false }
        if member["custom"] == nil { member["custom"] = [:] }
    }

    private static func parseCid(_ cid: String) -> (type: String, id: String)? {
        guard let colon = cid.firstIndex(of: ":") else { return nil }
        let type = String(cid[..<colon])
        let id = String(cid[cid.index(after: colon)...])
        return (type, id)
    }

    /// Stable RFC 3339 default for synthesized placeholders.
    private static let defaultDateString = "2020-01-01T00:00:00Z"
}

extension EventDecoder: AnyEventDecoder {}

private struct EventTypeEnvelope: Decodable {
    let type: EventType
    let cid: ChannelId?

    private enum CodingKeys: String, CodingKey {
        case type
        case cid
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(EventType.self, forKey: .type)
        // healthCheck events sometimes carry `cid == "*"` which isn't a real ChannelId.
        cid = try? container.decodeIfPresent(ChannelId.self, forKey: .cid)
    }
}
