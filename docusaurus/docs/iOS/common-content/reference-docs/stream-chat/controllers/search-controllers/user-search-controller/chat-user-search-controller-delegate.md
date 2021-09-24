---
title: ChatUserSearchControllerDelegate
---

`ChatUserSearchController` uses this protocol to communicate changes to its delegate.

``` swift
public protocol ChatUserSearchControllerDelegate: DataControllerStateDelegate 
```

## Inheritance

[`DataControllerStateDelegate`](../../../data-controller-state-delegate)

## Default Implementations

### `controller(_:didChangeUsers:)`

``` swift
func controller(
        _ controller: ChatUserSearchController,
        didChangeUsers changes: [ListChange<ChatUser>]
    ) 
```

## Requirements

### controller(\_:​didChangeUsers:​)

The controller changed the list of observed users.

``` swift
func controller(
        _ controller: ChatUserSearchController,
        didChangeUsers changes: [ListChange<ChatUser>]
    )
```

#### Parameters

  - controller: The controller emitting the change callback.
  - changes: The change to the list of users.
