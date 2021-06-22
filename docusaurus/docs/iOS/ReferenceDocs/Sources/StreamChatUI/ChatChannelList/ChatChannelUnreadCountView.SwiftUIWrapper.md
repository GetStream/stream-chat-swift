---
id: chatchannelunreadcountview.swiftuiwrapper 
title: ChatChannelUnreadCountView.SwiftUIWrapper
slug: /ReferenceDocs/Sources/StreamChatUI/ChatChannelList/chatchannelunreadcountview.swiftuiwrapper
---

SwiftUI wrapper of `_ChatChannelUnreadCountView`.
Servers to wrap custom SwiftUI view as a UIKit view so it can be easily injected into `_Components`.

``` swift
public class SwiftUIWrapper<Content: SwiftUIView>: _ChatChannelUnreadCountView<ExtraData>, ObservableObject
        where Content.ExtraData == ExtraData
```

## Inheritance

`ObservableObject`, `_ChatChannelUnreadCountView<ExtraData>`

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
