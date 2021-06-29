---
title: ChatMessageContentView.SwiftUIWrapper
---

SwiftUI wrapper of `_ChatMessageContentView`.
Servers to wrap custom SwiftUI view as a UIKit view so it can be easily injected into `_Components`.

``` swift
public class SwiftUIWrapper<Content: SwiftUIView>: _ChatMessageContentView<ExtraData>, ObservableObject
        where Content.ExtraData == ExtraData
```

## Inheritance

`ObservableObject`, `_ChatMessageContentView<ExtraData>`

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
