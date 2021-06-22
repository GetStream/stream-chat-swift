---
id: chatmessagebubbleview 
title: ChatMessageBubbleView
slug: /ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessage/chatmessagebubbleview
---

A view that displays a bubble around a message.

``` swift
open class _ChatMessageBubbleView<ExtraData: ExtraDataTypes>: _View, AppearanceProvider, SwiftUIRepresentable 
```

## Inheritance

[`_View`](../../CommonViews/_View), [`SwiftUIRepresentable`](../../CommonViews/SwiftUIRepresentable), [`AppearanceProvider`](../../Utils/AppearanceProvider)

## Properties

### `content`

The content this view is rendered based on.

``` swift
open var content: Content? 
```

## Methods

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```
