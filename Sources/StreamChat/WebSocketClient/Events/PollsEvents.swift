//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

protocol PollEventDTO: EventDTO {
    var poll: PollPayload? { get }
    var payload: EventPayload { get }
    static func createModel(poll: Poll, payload: EventPayload) -> Event?
}

protocol PollVoteEventDTO: EventDTO {
    var poll: PollPayload? { get }
    var vote: PollVotePayload? { get }
    var payload: EventPayload { get }
    static func createModel(vote: PollVote, poll: Poll, payload: EventPayload) -> Event?
}

extension PollVoteEventDTO {
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let vote,
              let voteDto = try? session.pollVote(id: vote.id, pollId: vote.pollId),
              let voteModel = try? voteDto.asModel(),
              let pollDto = try? session.poll(id: vote.pollId),
              let pollModel = try? pollDto.asModel() else {
            return nil
        }
        return Self.createModel(
            vote: voteModel,
            poll: pollModel,
            payload: payload
        )
    }
}

extension PollEventDTO {
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let poll, let pollDto = try? session.poll(id: poll.id),
              let pollModel = try? pollDto.asModel() else {
            return nil
        }
        return Self.createModel(
            poll: pollModel,
            payload: payload
        )
    }
}

public struct PollClosedEvent: Event {
    public let poll: Poll
    public let createdAt: Date?
}

struct PollClosedEventDTO: PollEventDTO {
    var poll: PollPayload?
    var payload: EventPayload

    init(from response: EventPayload) throws {
        payload = response
        poll = response.poll
    }
    
    static func createModel(poll: Poll, payload: EventPayload) -> Event? {
        PollClosedEvent(poll: poll, createdAt: payload.createdAt)
    }
}

public struct PollCreatedEvent: Event {
    public let poll: Poll
    public let createdAt: Date?
}

struct PollCreatedEventDTO: PollEventDTO {
    var poll: PollPayload?
    var payload: EventPayload

    init(from response: EventPayload) throws {
        payload = response
        poll = response.poll
    }
    
    static func createModel(poll: Poll, payload: EventPayload) -> Event? {
        PollCreatedEvent(poll: poll, createdAt: payload.createdAt)
    }
}

public struct PollDeletedEvent: Event {
    public let poll: Poll
    public let createdAt: Date?
}

struct PollDeletedEventDTO: PollEventDTO {
    var poll: PollPayload?
    var payload: EventPayload

    init(from response: EventPayload) throws {
        payload = response
        poll = response.poll
    }
    
    static func createModel(poll: Poll, payload: EventPayload) -> Event? {
        PollDeletedEvent(poll: poll, createdAt: payload.createdAt)
    }
}

public struct PollUpdatedEvent: Event {
    public let poll: Poll
    public let createdAt: Date?
}

struct PollUpdatedEventDTO: PollEventDTO {
    var poll: PollPayload?
    var payload: EventPayload

    init(from response: EventPayload) throws {
        payload = response
        poll = response.poll
    }
    
    static func createModel(poll: Poll, payload: EventPayload) -> Event? {
        PollUpdatedEvent(poll: poll, createdAt: payload.createdAt)
    }
}

public struct PollVoteCastedEvent: Event {
    public let vote: PollVote
    public let poll: Poll
    public let createdAt: Date?
}

struct PollVoteCastedEventDTO: PollVoteEventDTO {
    var vote: PollVotePayload?
    var poll: PollPayload?
    var payload: EventPayload

    init(from response: EventPayload) throws {
        payload = response
        vote = response.vote
        poll = response.poll
    }
    
    static func createModel(vote: PollVote, poll: Poll, payload: EventPayload) -> Event? {
        PollVoteCastedEvent(vote: vote, poll: poll, createdAt: payload.createdAt)
    }
}

public struct PollVoteChangedEvent: Event {
    public let vote: PollVote
    public let poll: Poll
    public let createdAt: Date?
}

struct PollVoteChangedEventDTO: PollVoteEventDTO {
    var vote: PollVotePayload?
    var poll: PollPayload?
    var payload: EventPayload

    init(from response: EventPayload) throws {
        payload = response
        vote = response.vote
        poll = response.poll
    }
    
    static func createModel(vote: PollVote, poll: Poll, payload: EventPayload) -> Event? {
        PollVoteChangedEvent(vote: vote, poll: poll, createdAt: payload.createdAt)
    }
}

public struct PollVoteRemovedEvent: Event {
    public let vote: PollVote
    public let poll: Poll
    public let createdAt: Date?
}

struct PollVoteRemovedEventDTO: PollVoteEventDTO {
    var vote: PollVotePayload?
    var poll: PollPayload?
    var payload: EventPayload

    init(from response: EventPayload) throws {
        payload = response
        vote = response.vote
        poll = response.poll
    }
    
    static func createModel(vote: PollVote, poll: Poll, payload: EventPayload) -> Event? {
        PollVoteRemovedEvent(vote: vote, poll: poll, createdAt: payload.createdAt)
    }
}
