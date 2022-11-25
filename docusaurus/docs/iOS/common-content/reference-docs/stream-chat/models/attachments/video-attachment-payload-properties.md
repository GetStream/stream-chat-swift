
### `type`

An attachment type all `MediaAttachmentPayload` instances conform to. Is set to `.video`.

``` swift
public static let type: AttachmentType = .video
```

### `title`

A title, usually the name of the video.

``` swift
public var title: String?
```

### `videoURL`

A link to the video.

``` swift
public var videoURL: URL
```

### `file`

The video itself.

``` swift
public var file: AttachmentFile
```

### `extraData`

An extra data.

``` swift
public var extraData: [String: RawJSON]?
```

## Methods

### `extraData(ofType:)`

Decodes extra data as an instance of the given type.

``` swift
public func extraData<T: Decodable>(ofType: T.Type = T.self) -> T? 
```

#### Parameters

  - `ofType`: The type an extra data should be decoded as.

#### Returns

Extra data of the given type or `nil` if decoding fails.

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
