
A `NavigationRouter` subclass that handles navigation actions of `ChatChannelListVC`.

``` swift
open class _ChatChannelListRouter<ExtraData: ExtraDataTypes>:
    NavigationRouter<_ChatChannelListVC<ExtraData>>,
    ComponentsProvider
```

## Inheritance

[`ComponentsProvider`](../Utils/ComponentsProvider), `NavigationRouter<_ChatChannelListVC<ExtraData>>`

## Methods

### `showCurrentUserProfile()`

Shows the view controller with the profile of the current user.

``` swift
open func showCurrentUserProfile() 
```

### `showMessageList(for:)`

Shows the view controller with messages for the provided cid.

``` swift
open func showMessageList(for cid: ChannelId) 
```

#### Parameters

  - cid: `ChannelId` of the channel the should be presented.

### `showCreateNewChannelFlow()`

Presents the user with the new channel creation flow.

``` swift
open func showCreateNewChannelFlow() 
```
