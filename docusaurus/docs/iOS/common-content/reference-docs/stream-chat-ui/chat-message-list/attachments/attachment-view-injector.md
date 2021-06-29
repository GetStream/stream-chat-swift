---
title: AttachmentViewInjector
---

An object used for injecting attachment views into `ChatMessageContentView`. The injector is also
responsible for updating the content of the injected views.

``` swift
open class _AttachmentViewInjector<ExtraData: ExtraDataTypes> 
```

> 

## Initializers

### `init(_:)`

Creates a new instance of the injector.

``` swift
public required init(_ contentView: _ChatMessageContentView<ExtraData>) 
```

#### Parameters

  - contentView: The target view used for injecting the views of this injector.

### `init?(coder:)`

``` swift
@available(*, unavailable)
    public required init?(coder: NSCoder) 
```

## Properties

### `contentView`

The target view used for injecting the views of this injector.

``` swift
public unowned let contentView: _ChatMessageContentView<ExtraData>
```

## Methods

### `contentViewDidPrepareForReuse()`

Called after `contentView.prepareForReuse` is called.

``` swift
open func contentViewDidPrepareForReuse() 
```

### `contentViewDidLayout(options:)`

Called after the `contentView` finished its `layout(options:​)` methods.

``` swift
open func contentViewDidLayout(options: ChatMessageLayoutOptions) 
```

### `contentViewDidUpdateContent()`

Called after `contentView.updateContent` is called.

``` swift
open func contentViewDidUpdateContent() 
```

### `attachments(payloadType:)`

``` swift
public func attachments<Payload: AttachmentPayload>(
        payloadType: Payload.Type
    ) -> [_ChatMessageAttachment<Payload>] 
```
