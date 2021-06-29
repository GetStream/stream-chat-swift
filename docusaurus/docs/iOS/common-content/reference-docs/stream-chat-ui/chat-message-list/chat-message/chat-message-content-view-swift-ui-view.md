---
title: ChatMessageContentViewSwiftUIView
---

``` swift
@available(iOS 13.0, *)
/// Protocol of `_ChatMessageContentView` wrapper for use in SwiftUI.
public protocol _ChatMessageContentViewSwiftUIView: View 
```

## Inheritance

`View`

## Requirements

### ExtraData

``` swift
associatedtype ExtraData: ExtraDataTypes
```

### init(dataSource:​)

``` swift
init(dataSource: _ChatMessageContentView<ExtraData>.ObservedObject<Self>)
```
