---
id: chatchannelunreadcountview 
title: ChatChannelUnreadCountView
slug: /ReferenceDocs/Sources/StreamChatUI/ChatChannelList/chatchannelunreadcountview
---

A view that shows a number of unread messages in channel.

``` swift
open class _ChatChannelUnreadCountView<ExtraData: ExtraDataTypes>: _View, ThemeProvider, SwiftUIRepresentable 
```

## Inheritance

[`_View`](../CommonViews/_View), [`SwiftUIRepresentable`](../CommonViews/SwiftUIRepresentable), [`ThemeProvider`](../Utils/ThemeProvider)

## Nested Type Aliases

### `ObservedObject`

Data source of `_ChatChannelUnreadCountView` represented as `ObservedObject`.

``` swift
public typealias ObservedObject<Content: SwiftUIView> = SwiftUIWrapper<Content> where Content.ExtraData == ExtraData
```

### `SwiftUIView`

`_ChatChannelUnreadCountView` represented in SwiftUI.

``` swift
public typealias SwiftUIView = _ChatChannelUnreadCountViewSwiftUIView
```

## Properties

### `unreadCountLabel`

The `UILabel` instance that holds number of unread messages.

``` swift
open private(set) lazy var unreadCountLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
```

### `content`

The data this view component shows.

``` swift
open var content: ChannelUnreadCount = .noUnread 
```

## Methods

### `layoutSubviews()`

``` swift
override open func layoutSubviews() 
```

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```
