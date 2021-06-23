---
title: ScrollToLatestMessageButton
---

A Button that is used to indicate unread messages in the Message list.

``` swift
open class _ScrollToLatestMessageButton<ExtraData: ExtraDataTypes>: _Button, ThemeProvider 
```

## Inheritance

[`_Button`](../../common-views/_button), [`ThemeProvider`](../../utils/theme-provider)

## Properties

### `unreadCountView`

The view showing number of unread messages in channel if any.

``` swift
open private(set) lazy var unreadCountView: _ChatMessageListUnreadCountView<ExtraData> = components
        .messageListUnreadCountView
        .init()
        .withoutAutoresizingMaskConstraints
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
