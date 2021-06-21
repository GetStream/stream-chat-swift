
`_ChatChannelMemberListController` uses this protocol to communicate changes to its delegate.

``` swift
public protocol _ChatChannelMemberListControllerDelegate: DataControllerStateDelegate 
```

If you're **not** using custom extra data types, you can use a convenience version of this protocol
named `ChatChannelMemberListControllerDelegate`, which hides the generic types, and make the usage easier.

## Inheritance

[`DataControllerStateDelegate`](../DataControllerStateDelegate)

## Default Implementations

### `memberListController(_:didChangeMembers:)`

``` swift
func memberListController(
        _ controller: _ChatChannelMemberListController<ExtraData>,
        didChangeMembers changes: [ListChange<_ChatChannelMember<ExtraData.User>>]
    ) 
```

## Requirements

### ExtraData

``` swift
associatedtype ExtraData: ExtraDataTypes
```

### memberListController(\_:​didChangeMembers:​)

Controller observed a change in the channel member list.

``` swift
func memberListController(
        _ controller: _ChatChannelMemberListController<ExtraData>,
        didChangeMembers changes: [ListChange<_ChatChannelMember<ExtraData.User>>]
    )
```
