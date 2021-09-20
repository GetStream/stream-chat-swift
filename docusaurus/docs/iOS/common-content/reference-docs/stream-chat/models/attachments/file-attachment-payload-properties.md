
### `type`

An attachment type all `FileAttachmentPayload` instances conform to. Is set to `.file`.

``` swift
public static let type: AttachmentType = .file
```

### `title`

A title, usually the name of the file.

``` swift
public var title: String?
```

### `assetURL`

A link to the file.

``` swift
public var assetURL: URL
```

### `file`

The file itself.

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

  - ofType: The type an extra data should be decoded as.

#### Returns

Extra data of the given type or `nil` if decoding fails.

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
