---
title: ChatMessageFileAttachmentListView
---

View which holds one or more file attachment views in a message or composer attachment view

``` swift
open class ChatMessageFileAttachmentListView: _View, ComponentsProvider 
```

## Inheritance

[`_View`](../../../common-views/_view), [`ComponentsProvider`](../../../utils/components-provider)

## Properties

### `content`

Content of the attachment list - Array of `ChatMessageFileAttachment`

``` swift
open var content: [ChatMessageFileAttachment] = [] 
```

### `didTapOnAttachment`

Closure what should happen on tapping the given attachment.

``` swift
open var didTapOnAttachment: ((ChatMessageFileAttachment) -> Void)?
```

### `containerStackView`

Container which holds one or multiple attachment views in self.

``` swift
open private(set) lazy var containerStackView: ContainerStackView = ContainerStackView().withoutAutoresizingMaskConstraints
```

## Methods

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```
