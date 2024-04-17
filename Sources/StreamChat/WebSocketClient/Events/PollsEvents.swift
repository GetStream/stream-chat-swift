//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct PollClosedEventDTO: EventDTO {
    var poll: PollPayload?
    var payload: EventPayload

    init(payload: EventPayload, poll: PollPayload? = nil) {
        self.payload = payload
        self.poll = poll
    }
}

struct PollCreatedEventDTO: EventDTO {
    var poll: PollPayload?
    var payload: EventPayload

    init(payload: EventPayload, poll: PollPayload? = nil) {
        self.payload = payload
        self.poll = poll
    }
}

struct PollDeletedEventDTO: EventDTO {
    var poll: PollPayload?
    var payload: EventPayload

    init(payload: EventPayload, poll: PollPayload? = nil) {
        self.payload = payload
        self.poll = poll
    }
}

struct PollUpdatedEventDTO: EventDTO {
    var poll: PollPayload?
    var payload: EventPayload

    init(payload: EventPayload, poll: PollPayload? = nil) {
        self.payload = payload
        self.poll = poll
    }
}

struct PollVoteCastedEventDTO: EventDTO {
    var vote: PollVotePayload?
    var payload: EventPayload

    init(payload: EventPayload, vote: PollVotePayload? = nil) {
        self.payload = payload
        self.vote = vote
    }
}

struct PollVoteChangedEventDTO: EventDTO {
    var vote: PollVotePayload?
    var payload: EventPayload

    init(payload: EventPayload, vote: PollVotePayload? = nil) {
        self.payload = payload
        self.vote = vote
    }
}

struct PollVoteRemovedEventDTO: EventDTO {
    var vote: PollVotePayload?
    var payload: EventPayload

    init(payload: EventPayload, vote: PollVotePayload? = nil) {
        self.payload = payload
        self.vote = vote
    }
}
