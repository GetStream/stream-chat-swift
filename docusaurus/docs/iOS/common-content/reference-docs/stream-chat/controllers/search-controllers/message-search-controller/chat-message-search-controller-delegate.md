---
title: ChatMessageSearchControllerDelegate
---

`ChatMessageSearchController` uses this protocol to communicate changes to its delegate.

``` swift
public protocol ChatMessageSearchControllerDelegate: DataControllerStateDelegate 
```

## Inheritance

[`DataControllerStateDelegate`](../../../data-controller-state-delegate)

## Requirements

### controller(\_:​didChangeMessages:​)

The controller changed the list of observed messages.

``` swift
func controller(
        _ controller: ChatMessageSearchController,
        didChangeMessages changes: [ListChange<ChatMessage>]
    )
```

#### Parameters

  - controller: The controller emitting the change callback.
  - changes: The change to the list of messages.
