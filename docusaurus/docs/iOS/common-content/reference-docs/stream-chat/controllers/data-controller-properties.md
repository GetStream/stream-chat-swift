
### `state`

The current state of the controller.

``` swift
public internal(set) var state: State = .initialized 
```

### `callbackQueue`

The queue which is used to perform callback calls. The default value is `.main`.

``` swift
public var callbackQueue: DispatchQueue = .main
```

## Methods

### `synchronize(_:)`

Synchronize local data with remote.

``` swift
public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) 
```

**Asynchronously** fetches the latest version of the data from the servers. Once the remote fetch is completed,
the completion block is called. If the updated data differ from the locally cached ones, the controller uses the
callback methods (delegate, `Combine` publishers, etc.) to inform about the changes.

#### Parameters

