
### `type`

A type of attachment that will be created when the message is sent.

``` swift
public let type: AttachmentType
```

### `payload`

A payload that will exposed on attachment when the message is sent.

``` swift
public let payload: Encodable
```

### `localFileURL`

A URL referencing to the local file that should be uploaded.

``` swift
public let localFileURL: URL?
