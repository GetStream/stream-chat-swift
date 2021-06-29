
### `type`

An attachment type all `GiphyAttachmentPayload` instances conform to. Is set to `.giphy`.

``` swift
public static let type: AttachmentType = .giphy
```

### `title`

A  title, usually the search request used to find the gif.

``` swift
public let title: String
```

### `previewURL`

A link to gif file.

``` swift
public let previewURL: URL
```

### `actions`

Actions when gif is not sent yet. (e.g. `Shuffle`)

``` swift
public let actions: [AttachmentAction]
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
