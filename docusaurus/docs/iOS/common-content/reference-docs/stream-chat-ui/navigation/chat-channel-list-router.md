---
title: ChatChannelListRouter
---

A `NavigationRouter` subclass that handles navigation actions of `ChatChannelListVC`.

``` swift
@available(iOSApplicationExtension, unavailable)
open class ChatChannelListRouter: NavigationRouter<ChatChannelListVC>, ComponentsProvider 
```

## Inheritance

[`ComponentsProvider`](../../utils/components-provider), `NavigationRouter<ChatChannelListVC>`

## Methods

### `showCurrentUserProfile()`

Shows the view controller with the profile of the current user.

``` swift
open func showCurrentUserProfile() 
```

### `showChannel(for:)`

Shows the view controller with messages for the provided cid.

``` swift
open func showChannel(for cid: ChannelId) 
```

#### Parameters

  - cid: `ChannelId` of the channel the should be presented.

### `didTapMoreButton(for:)`

Called when a user tapped `More` swipe action on a channel

``` swift
open func didTapMoreButton(for cid: ChannelId) 
```

#### Parameters

  - cid: `ChannelId` of a channel swipe acton was used on

### `didTapDeleteButton(for:)`

Called when a user tapped `Delete` swipe action on a channel

``` swift
open func didTapDeleteButton(for cid: ChannelId) 
```

#### Parameters

  - cid: `ChannelId` of a channel swipe acton was used on
