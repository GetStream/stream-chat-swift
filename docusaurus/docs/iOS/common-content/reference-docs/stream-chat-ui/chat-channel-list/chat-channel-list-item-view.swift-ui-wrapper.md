---
title: ChatChannelListItemView.SwiftUIWrapper
---

SwiftUI wrapper of `_ChatChannelListItemView`.
Servers to wrap custom SwiftUI view as a UIKit view so it can be easily injected into `_Components`.

``` swift
public class SwiftUIWrapper<Content: SwiftUIView>: ChatChannelListItemView, ObservableObject 
```

## Inheritance

[`ChatChannelListItemView`](../chat-channel-list-item-view), `ObservableObject`

## Properties

### `intrinsicContentSize`

``` swift
override public var intrinsicContentSize: CGSize 
```

## Methods

### `setUp()`

``` swift
override public func setUp() 
```

### `setUpLayout()`

``` swift
override public func setUpLayout() 
```

### `updateContent()`

``` swift
override public func updateContent() 
```
