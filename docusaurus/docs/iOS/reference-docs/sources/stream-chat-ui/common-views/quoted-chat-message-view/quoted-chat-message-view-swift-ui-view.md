---
title: QuotedChatMessageViewSwiftUIView
---

``` swift
@available(iOS 13.0, *)
/// Protocol of `QuotedChatMessageView` wrapper for use in SwiftUI.
public protocol _QuotedChatMessageViewSwiftUIView: View 
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
init(dataSource: _QuotedChatMessageView<ExtraData>.ObservedObject<Self>)
```
