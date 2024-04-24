//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct PollClosedEventDTO: EventDTO {
    var poll: PollPayload?
    var payload: EventPayload

    init(from response: EventPayload) throws {
        payload = response
        poll = response.poll
    }
}

struct PollCreatedEventDTO: EventDTO {
    var poll: PollPayload?
    var payload: EventPayload

    init(from response: EventPayload) throws {
        payload = response
        poll = response.poll
    }
}

struct PollDeletedEventDTO: EventDTO {
    var poll: PollPayload?
    var payload: EventPayload

    init(from response: EventPayload) throws {
        payload = response
        poll = response.poll
    }
}

struct PollUpdatedEventDTO: EventDTO {
    var poll: PollPayload?
    var payload: EventPayload

    init(from response: EventPayload) throws {
        payload = response
        poll = response.poll
    }
}

struct PollVoteCastedEventDTO: EventDTO {
    var vote: PollVotePayload?
    var poll: PollPayload?
    var payload: EventPayload

    init(from response: EventPayload) throws {
        payload = response
        vote = response.vote
        poll = response.poll
    }
}

struct PollVoteChangedEventDTO: EventDTO {
    var vote: PollVotePayload?
    var poll: PollPayload?
    var payload: EventPayload

    init(from response: EventPayload) throws {
        payload = response
        vote = response.vote
        poll = response.poll
    }
}

struct PollVoteRemovedEventDTO: EventDTO {
    var vote: PollVotePayload?
    var poll: PollPayload?
    var payload: EventPayload

    init(from response: EventPayload) throws {
        payload = response
        vote = response.vote
        poll = response.poll
    }
}
