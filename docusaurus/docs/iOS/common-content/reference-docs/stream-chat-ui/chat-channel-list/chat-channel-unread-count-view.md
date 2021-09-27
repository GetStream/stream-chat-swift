---
title: ChatChannelUnreadCountView
---

A view that shows a number of unread messages in channel.

``` swift
open class ChatChannelUnreadCountView: _View, ThemeProvider, SwiftUIRepresentable 
```

## Inheritance

[`_View`](../../common-views/_view), [`SwiftUIRepresentable`](../../common-views/swift-ui-representable), [`ThemeProvider`](../../utils/theme-provider)

## Nested Type Aliases

### `ObservedObject`

Data source of `_ChatChannelUnreadCountView` represented as `ObservedObject`.

``` swift
public typealias ObservedObject<Content: SwiftUIView> = SwiftUIWrapper<Content>
```

### `SwiftUIView`

`_ChatChannelUnreadCountView` represented in SwiftUI.

``` swift
public typealias SwiftUIView = ChatChannelUnreadCountViewSwiftUIView
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
