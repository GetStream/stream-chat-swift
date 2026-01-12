//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

/// A model representing an event where a poll was closed.
public final class PollClosedEvent: Event {
    /// The poll that was closed.
    public let poll: Poll
    
    /// The date and time when the event was created.
    /// This property is optional and may be `nil`.
    public let createdAt: Date?

    init(poll: Poll, createdAt: Date?) {
        self.poll = poll
        self.createdAt = createdAt
    }
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

/// A model representing an event where a poll was created.
public final class PollCreatedEvent: Event {
    /// The poll that was created.
    public let poll: Poll
    
    /// The date and time when the event was created.
    /// This property is optional and may be `nil`.
    public let createdAt: Date?

    init(poll: Poll, createdAt: Date?) {
        self.poll = poll
        self.createdAt = createdAt
    }
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

/// A model representing an event where a poll was deleted.
public final class PollDeletedEvent: Event {
    /// The poll that was deleted.
    public let poll: Poll
    
    /// The date and time when the event was created.
    /// This property is optional and may be `nil`.
    public let createdAt: Date?

    init(poll: Poll, createdAt: Date?) {
        self.poll = poll
        self.createdAt = createdAt
    }
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

/// A model representing an event where a poll was updated.
public final class PollUpdatedEvent: Event {
    /// The poll that was updated.
    public let poll: Poll
    
    /// The date and time when the event was created.
    /// This property is optional and may be `nil`.
    public let createdAt: Date?

    init(poll: Poll, createdAt: Date?) {
        self.poll = poll
        self.createdAt = createdAt
    }
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

/// A model representing an event where a vote was casted in a poll.
public final class PollVoteCastedEvent: Event {
    /// The vote that was casted.
    public let vote: PollVote
    
    /// The poll in which the vote was casted.
    public let poll: Poll
    
    /// The date and time when the event was created.
    /// This property is optional and may be `nil`.
    public let createdAt: Date?

    init(vote: PollVote, poll: Poll, createdAt: Date?) {
        self.vote = vote
        self.poll = poll
        self.createdAt = createdAt
    }
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

/// A model representing an event where a vote was changed in a poll.
public final class PollVoteChangedEvent: Event {
    /// The vote that was changed.
    public let vote: PollVote
    
    /// The poll in which the vote was changed.
    public let poll: Poll
    
    /// The date and time when the event was created.
    /// This property is optional and may be `nil`.
    public let createdAt: Date?

    init(vote: PollVote, poll: Poll, createdAt: Date?) {
        self.vote = vote
        self.poll = poll
        self.createdAt = createdAt
    }
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

/// A model representing an event where a vote was removed from a poll.
public final class PollVoteRemovedEvent: Event {
    /// The vote that was removed.
    public let vote: PollVote
    
    /// The poll from which the vote was removed.
    public let poll: Poll
    
    /// The date and time when the event was created.
    /// This property is optional and may be `nil`.
    public let createdAt: Date?

    init(vote: PollVote, poll: Poll, createdAt: Date?) {
        self.vote = vote
        self.poll = poll
        self.createdAt = createdAt
    }
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
