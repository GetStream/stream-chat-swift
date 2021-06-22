---
id: quotedchatmessageview.swiftuiwrapper 
title: QuotedChatMessageView.SwiftUIWrapper
slug: /ReferenceDocs/Sources/StreamChatUI/CommonViews/QuotedChatMessageView/quotedchatmessageview.swiftuiwrapper
---

SwiftUI wrapper of `QuotedChatMessageView`.

``` swift
public class SwiftUIWrapper<Content: SwiftUIView>: _QuotedChatMessageView<ExtraData>, ObservableObject
        where Content.ExtraData == ExtraData
```

## Inheritance

`ObservableObject`, `_QuotedChatMessageView<ExtraData>`

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
