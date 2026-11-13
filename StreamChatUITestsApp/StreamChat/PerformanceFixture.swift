//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

#if TESTS
import Foundation
import OHHTTPStubs
import StreamChat

// A channel the app serves to itself, so the performance tests scroll the same content on every run.
// The performance tests run on a Firebase Test Lab device, which can't reach the mock server on the CI runner.
// Only this channel's requests are stubbed: login and the web socket still go to the real backend.
enum PerformanceFixture {
    static let launchArgument = "PERFORMANCE_FIXTURE"
    static let cid = ChannelId(type: .messaging, id: "performance-fixture")

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    private static let messageCount = 300
    private static let defaultPageSize = 25
    private static let baseDate = Date(timeIntervalSince1970: 1_704_099_600) // 2024-01-01 09:00 UTC

    private static let texts = [
        "Hey, are we still on for today?",
        "Yes! See you at the hangar at noon.",
        "I've got a bad feeling about this.",
        "The new build is up. Can someone check the onboarding flow on a small screen?",
        "👍",
        "Sure, give me ten minutes.",
        "Here are my notes from the meeting:\n- move the release to Thursday\n- fix the crash in the composer\n- update the docs",
        "Did anyone see the dashboard? The numbers look great this week.",
        "lol",
        "Remember to bring the charts, the ones we printed yesterday, and the spare power cells for the scanner.",
        "On my way 🚀",
        "Never tell me the odds. This has worked every single time, and it will work this time too, trust me."
    ]

    static func install(currentUserId: UserId) {
        HTTPStubs.stubRequests(passingTest: { request in
            request.url?.path.contains("/channels/\(cid.type.rawValue)/\(cid.id)/") ?? false
        }, withStubResponse: { request in
            let json: [String: Any]
            if request.url?.lastPathComponent == "query" {
                json = channelState(currentUserId: currentUserId, pagination: pagination(of: request))
            } else {
                json = ["duration": "0.00ms"]
            }
            let data = (try? JSONSerialization.data(withJSONObject: json)) ?? Data()
            return HTTPStubsResponse(data: data, statusCode: 200, headers: ["Content-Type": "application/json"])
        })
    }

    private static func pagination(of request: URLRequest) -> (limit: Int, idLt: String?) {
        guard
            let body = (request as NSURLRequest).ohhttpStubs_HTTPBody(),
            let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
            let messages = json["messages"] as? [String: Any]
        else { return (defaultPageSize, nil) }
        return (messages["limit"] as? Int ?? defaultPageSize, messages["id_lt"] as? String)
    }

    private static func channelState(currentUserId: UserId, pagination: (limit: Int, idLt: String?)) -> [String: Any] {
        let users = [currentUserId, "leia_organa", "han_solo", "chewbacca"].map(user)
        let end = pagination.idLt.flatMap(messageIndex) ?? messageCount
        let start = max(0, end - pagination.limit)
        let messages = (start..<end).map { message(at: $0, users: users) }

        return [
            "channel": [
                "cid": cid.rawValue,
                "id": cid.id,
                "type": cid.type.rawValue,
                "name": "Performance",
                "member_count": users.count,
                "created_at": date(0),
                "updated_at": date(0),
                "last_message_at": date(messageCount - 1),
                "disabled": false,
                "frozen": false,
                "own_capabilities": ["send-message", "send-reaction", "send-reply", "quote-message", "read-events"],
                "config": [
                    "reactions": true,
                    "typing_events": false,
                    "read_events": true,
                    "connect_events": true,
                    "replies": true,
                    "quotes": true,
                    "search": true,
                    "mutes": true,
                    "uploads": true,
                    "url_enrichment": false,
                    "message_retention": "infinite",
                    "max_message_length": 5000,
                    "created_at": date(0),
                    "updated_at": date(0)
                ]
            ],
            "members": users.map { user in
                [
                    "user_id": user["id"]!,
                    "user": user,
                    "channel_role": "channel_member",
                    "created_at": date(0),
                    "updated_at": date(0)
                ]
            },
            "messages": messages,
            "pinned_messages": [],
            "threads": [],
            "read": [],
            "watcher_count": 0,
            "watchers": []
        ]
    }

    // Messages come in runs of three from the same author, so the list groups them like a real conversation.
    private static func message(at index: Int, users: [[String: Any]]) -> [String: Any] {
        let author = users[(index / 3) % users.count]
        var message = baseMessage(at: index, author: author)

        if index % 7 == 0 {
            let reactor = users[(index + 1) % users.count]
            message["reaction_groups"] = [
                "like": ["count": 1, "sum_scores": 1, "first_reaction_at": date(index), "last_reaction_at": date(index)]
            ]
            message["latest_reactions"] = [[
                "type": "like",
                "score": 1,
                "message_id": messageId(index),
                "user_id": reactor["id"]!,
                "user": reactor,
                "created_at": date(index),
                "updated_at": date(index)
            ]]
        }
        if index % 11 == 0 {
            message["reply_count"] = 3
        }
        if index % 13 == 0, index > 0 {
            message["quoted_message_id"] = messageId(index - 1)
            message["quoted_message"] = baseMessage(at: index - 1, author: users[((index - 1) / 3) % users.count])
        }
        return message
    }

    private static func baseMessage(at index: Int, author: [String: Any]) -> [String: Any] {
        [
            "id": messageId(index),
            "cid": cid.rawValue,
            "type": "regular",
            "text": texts[index % texts.count],
            "user": author,
            "created_at": date(index),
            "updated_at": date(index),
            "reply_count": 0,
            "deleted_reply_count": 0,
            "attachments": [],
            "latest_reactions": [],
            "own_reactions": [],
            "mentioned_users": []
        ]
    }

    private static func user(_ id: String) -> [String: Any] {
        [
            "id": id,
            "name": id.split(separator: "_").map(\.capitalized).joined(separator: " "),
            "role": "user",
            "online": false,
            "created_at": date(0),
            "updated_at": date(0)
        ]
    }

    private static func messageId(_ index: Int) -> String {
        String(format: "performance-fixture-%04d", index)
    }

    private static func messageIndex(_ id: String) -> Int? {
        id.split(separator: "-").last.flatMap { Int($0) }
    }

    private static func date(_ index: Int) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: baseDate.addingTimeInterval(TimeInterval(index * 60)))
    }
}
#endif
