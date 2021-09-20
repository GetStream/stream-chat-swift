
### `id`

The attachment identifier.

``` swift
public let id: AttachmentId
```

### `type`

The attachment type.

``` swift
public let type: AttachmentType
```

### `payload`

The attachment payload.

``` swift
public var payload: Payload
```

### `uploadingState`

The uploading state of the attachment.

``` swift
public let uploadingState: AttachmentUploadingState?
```

Reflects uploading progress for local attachments that require file uploading.
Is `nil` for local attachments that don't need to be uploaded.

