---
id: chatusersearchcontrollerdelegate 
title: ChatUserSearchControllerDelegate
slug: referencedocs/sources/streamchat/controllers/searchcontrollers/chatusersearchcontrollerdelegate
---

`ChatUserSearchController` uses this protocol to communicate changes to its delegate.

``` swift
public protocol _ChatUserSearchControllerDelegate: DataControllerStateDelegate 
```

If you're **not** using custom extra data types, you can use a convenience version of this protocol
named `ChatUserSearchControllerDelegate`, which hides the generic types, and make the usage easier.

## Inheritance

[`DataControllerStateDelegate`](../DataControllerStateDelegate)

## Default Implementations

### `controller(_:didChangeUsers:)`

``` swift
func controller(
        _ controller: _ChatUserSearchController<ExtraData>,
        didChangeUsers changes: [ListChange<_ChatUser<ExtraData.User>>]
    ) 
```

## Requirements

### ExtraData

``` swift
associatedtype ExtraData: ExtraDataTypes
```

### controller(\_:​didChangeUsers:​)

The controller changed the list of observed users.

``` swift
func controller(
        _ controller: _ChatUserSearchController<ExtraData>,
        didChangeUsers changes: [ListChange<_ChatUser<ExtraData.User>>]
    )
```

#### Parameters

  - controller: The controller emitting the change callback.
  - changes: The change to the list of users.
