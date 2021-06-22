---
id: chatchannellistitemviewswiftuiview 
title: ChatChannelListItemViewSwiftUIView
slug: /ReferenceDocs/Sources/StreamChatUI/ChatChannelList/chatchannellistitemviewswiftuiview
---

``` swift
@available(iOS 13.0, *)
/// Protocol of `_ChatChannelListItemView` wrapper for use in SwiftUI.
public protocol _ChatChannelListItemViewSwiftUIView: View 
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
init(dataSource: _ChatChannelListItemView<ExtraData>.ObservedObject<Self>)
```
