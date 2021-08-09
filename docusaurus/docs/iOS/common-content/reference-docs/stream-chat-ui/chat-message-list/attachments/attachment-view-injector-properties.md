
### `fillAllAvailableWidth`

Says whether a message content should start filling all available width.
Is `true` by default.

``` swift
open var fillAllAvailableWidth: Bool = true
```

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
