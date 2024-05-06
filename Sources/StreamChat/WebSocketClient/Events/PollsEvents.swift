//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

protocol PollVoteEventDTO: EventDTO {
    var poll: PollPayload? { get }
    var vote: PollVotePayload? { get }
}

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

public struct PollVoteCastedEvent: Event {
    public let vote: PollVote
    public let poll: Poll
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
    
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let vote,
              let voteDto = try? session.pollVote(id: vote.id, pollId: vote.pollId),
              let voteModel = try? voteDto.asModel(),
              let pollDto = try? session.poll(id: vote.pollId),
              let pollModel = try? pollDto.asModel() else {
            return nil
        }
        return PollVoteCastedEvent(
            vote: voteModel,
            poll: pollModel
        )
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
