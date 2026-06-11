//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A model representing an event where a poll was created.
@available(*, deprecated, message: "The server never delivers poll.created; new polls arrive through message.new with the poll attached.")
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

extension PollClosedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let pollDto = try? session.poll(id: poll.id),
              let pollModel = try? pollDto.asModel() else { return nil }
        return PollClosedEvent(poll: pollModel, createdAt: createdAt)
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

extension PollDeletedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let pollDto = try? session.poll(id: poll.id),
              let pollModel = try? pollDto.asModel() else { return nil }
        return PollDeletedEvent(poll: pollModel, createdAt: createdAt)
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

extension PollUpdatedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let pollDto = try? session.poll(id: poll.id),
              let pollModel = try? pollDto.asModel() else { return nil }
        return PollUpdatedEvent(poll: pollModel, createdAt: createdAt)
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

extension PollVoteCastedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let voteDto = try? session.pollVote(id: pollVote.id, pollId: pollVote.pollId),
              let voteModel = try? voteDto.asModel(),
              let pollDto = try? session.poll(id: pollVote.pollId),
              let pollModel = try? pollDto.asModel() else { return nil }
        return PollVoteCastedEvent(vote: voteModel, poll: pollModel, createdAt: createdAt)
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

extension PollVoteChangedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let voteDto = try? session.pollVote(id: pollVote.id, pollId: pollVote.pollId),
              let voteModel = try? voteDto.asModel(),
              let pollDto = try? session.poll(id: pollVote.pollId),
              let pollModel = try? pollDto.asModel() else { return nil }
        return PollVoteChangedEvent(vote: voteModel, poll: pollModel, createdAt: createdAt)
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

extension PollVoteRemovedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let voteDto = try? session.pollVote(id: pollVote.id, pollId: pollVote.pollId),
              let voteModel = try? voteDto.asModel(),
              let pollDto = try? session.poll(id: pollVote.pollId),
              let pollModel = try? pollDto.asModel() else { return nil }
        return PollVoteRemovedEvent(vote: voteModel, poll: pollModel, createdAt: createdAt)
    }
}
