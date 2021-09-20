
### `type`

An attachment type all `ImageAttachmentPayload` instances conform to. Is set to `.image`.

``` swift
public static let type: AttachmentType = .image
```

### `title`

A title, usually the name of the image.

``` swift
public var title: String?
```

### `imageURL`

A link to the image.

``` swift
public var imageURL: URL
```

### `imagePreviewURL`

A link to the image preview.

``` swift
public var imagePreviewURL: URL
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
