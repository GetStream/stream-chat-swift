
### `type`

An attachment file type (see `AttachmentFileType`).

``` swift
public let type: AttachmentFileType
```

### `size`

A size of the file.

``` swift
public let size: Int64
```

### `mimeType`

A mime type.

``` swift
public let mimeType: String?
```

### `sizeFormatter`

A file size formatter.

``` swift
public static let sizeFormatter 
```

### `sizeString`

A formatted file size.

``` swift
public var sizeString: String 
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
