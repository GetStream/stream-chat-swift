
### `apiKey`

The `APIKey` unique for your chat app.

``` swift
public let apiKey: APIKey
```

The API key can be obtained by registering on \[our website\](https://getstream.io/chat/).

### `applicationGroupIdentifier`

The security application group ID to use for the local storage. This is needed if you want to share offline storage between
your chat application and extensions. More information is available [here](https:​//developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)
and [here](https:​//developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html#//apple_ref/doc/uid/TP40011195-CH4-SW19)

``` swift
public var applicationGroupIdentifier: String? 
```

### `localStorageFolderURL`

The folder `ChatClient` uses to store its local cache files.

``` swift
public var localStorageFolderURL: URL? 
```

### `baseURL`

The datacenter `ChatClient` uses for connecting.

``` swift
public var baseURL: BaseURL = .usEast
```

### `isLocalStorageEnabled`

Determines whether `ChatClient` caches the data locally. This makes it possible to browse the existing chat data also
when the internet connection is not available.

``` swift
public var isLocalStorageEnabled: Bool = false
```

### `shouldFlushLocalStorageOnStart`

If set to `true`, `ChatClient` resets the local cache on the start.

``` swift
public var shouldFlushLocalStorageOnStart: Bool = false
```

You should set `shouldFlushLocalStorageOnStart = true` every time the changes in your code makes the local cache invalid.

### `localCaching`

Advanced settings for the local caching and model serialization.

``` swift
public var localCaching 
```

### `isClientInActiveMode`

Flag for setting a ChatClient instance in connection-less mode.
A connection-less client is not able to connect to websocket and will not
receive websocket events. It can still observe and mutate database.
This flag is automatically set to `false` for app extensions
**Warning**:​ There should be at max 1 active client at the same time, else it can lead to undefined behavior.

``` swift
public var isClientInActiveMode: Bool
```

### `shouldConnectAutomatically`

If set to `true` the `ChatClient` will automatically establish a web-socket
connection to listen to the updates when `reloadUserIfNeeded` is called.

``` swift
@available(
        *,
        deprecated,
        message: "This flag has no effect anymore. The flow for setting and for connecting the user has been unified to the `connectUser` set of methods."
    )
    public var shouldConnectAutomatically = true
```

If set to `false` the connection won't be established automatically
but has to be initiated manually by calling `connect`.

Is `true` by default.

### `staysConnectedInBackground`

If set to `true`, the `ChatClient` will try to stay connected while app is backgrounded.
If set to `false`, websocket disconnects immediately when app is backgrounded.

``` swift
public var staysConnectedInBackground = true
```

This flag aims to reduce unnecessary reconnections while quick app switches,
like when a user just checks a notification or another app.
`ChatClient` starts a background task to keep the connection alive,
and disconnects when background task expires.
`ChatClient` tries to stay connected while in background up to 5 minutes.
Usually, disconnection occurs around 2-3 minutes.

> 

Default value is `true`

### `customCDNClient`

Creates a new instance of `ChatClientConfig`.

``` swift
public var customCDNClient: CDNClient?
```

Allows to inject a custom API client for uploading attachments, if not specified `StreamCDNClient` is used

#### Parameters

  - apiKey: The API key of the chat app the `ChatClient` connects to.

### `maxAttachmentSize`

Returns max possible attachment size in bytes.
The value is taken from custom `maxAttachmentSize` type custom `CDNClient` type.
The default value is 20 MiB.

``` swift
public var maxAttachmentSize: Int64 
```

### `deletedMessagesVisibility`

Specifies the visibility of deleted messages.

``` swift
public var deletedMessagesVisibility: DeletedMessageVisibility = .visibleForCurrentUser
