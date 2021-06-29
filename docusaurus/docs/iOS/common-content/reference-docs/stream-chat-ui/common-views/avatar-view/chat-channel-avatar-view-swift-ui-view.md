---
title: ChatChannelAvatarViewSwiftUIView
---

``` swift
@available(iOS 13.0, *)
/// Protocol of `_ChatChannelAvatarView` wrapper for use in SwiftUI.
public protocol _ChatChannelAvatarViewSwiftUIView: View 
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
init(dataSource: _ChatChannelAvatarView<ExtraData>.ObservedObject<Self>)
```
