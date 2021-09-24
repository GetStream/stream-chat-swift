---
title: ChatMessageReaction
---

A type representing a message reaction. `ChatMessageReaction` is an immutable snapshot
of a message reaction entity at the given time.

``` swift
public struct ChatMessageReaction: Hashable 
```

## Inheritance

`Hashable`

## Properties

### `type`

The reaction type.

``` swift
public let type: MessageReactionType
```

### `score`

The reaction score.

``` swift
public let score: Int
```

### `createdAt`

The date the reaction was created.

``` swift
public let createdAt: Date
```

### `updatedAt`

The date the reaction was last updated.

``` swift
public let updatedAt: Date
```

### `extraData`

Custom data

``` swift
public let extraData: [String: RawJSON]
```

### `author`

The author.

``` swift
public let author: ChatUser
```
