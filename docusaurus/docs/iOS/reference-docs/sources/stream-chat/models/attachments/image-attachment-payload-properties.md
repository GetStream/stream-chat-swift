
### `type`

An attachment type all `ImageAttachmentPayload` instances conform to. Is set to `.image`.

``` swift
public static let type: AttachmentType = .image
```

### `title`

A title, usually the name of the image.

``` swift
public let title: String?
```

### `imageURL`

A link to the image.

``` swift
public internal(set) var imageURL: URL
```

### `imagePreviewURL`

A link to the image preview.

``` swift
public let imagePreviewURL: URL
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
