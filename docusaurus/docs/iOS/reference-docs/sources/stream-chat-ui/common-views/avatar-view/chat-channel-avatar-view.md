---
title: ChatChannelAvatarView
---

A view that shows a channel avatar including an online indicator if any user is online.

``` swift
open class _ChatChannelAvatarView<ExtraData: ExtraDataTypes>: _View, ThemeProvider, SwiftUIRepresentable 
```

## Inheritance

[`_View`](../_view.md), [`SwiftUIRepresentable`](../swift-ui-representable.md), [`ThemeProvider`](../../utils/theme-provider.md)

## Nested Type Aliases

### `ObservedObject`

Data source of `_ChatChannelAvatarView` represented as `ObservedObject`.

``` swift
public typealias ObservedObject<Content: SwiftUIView> = SwiftUIWrapper<Content> where Content.ExtraData == ExtraData
```

### `SwiftUIView`

`_ChatChannelAvatarView` represented in SwiftUI.

``` swift
public typealias SwiftUIView = _ChatChannelAvatarViewSwiftUIView
```

## Properties

### `presenceAvatarView`

A view that shows the avatar image

``` swift
open private(set) lazy var presenceAvatarView: _ChatPresenceAvatarView<ExtraData> = components
        .presenceAvatarView.init()
        .withoutAutoresizingMaskConstraints
```

### `content`

The data this view component shows.

``` swift
open var content: (channel: _ChatChannel<ExtraData>?, currentUserId: UserId?) 
```

## Methods

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```
