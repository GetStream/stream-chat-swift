
## Properties

### `isInteractionEnabled`

A boolean value that checks if actions are available on the message (e.g. `edit`, `delete`, `resend`, etc.).

``` swift
var isInteractionEnabled: Bool 
```

### `isLastActionFailed`

A boolean value that checks if the last action (`send`, `edit` or `delete`) on the message failed.

``` swift
var isLastActionFailed: Bool 
```

### `isRootOfThread`

A boolean value that checks if the message is the root of a thread.

``` swift
var isRootOfThread: Bool 
```

### `isPartOfThread`

A boolean value that checks if the message is part of a thread.

``` swift
var isPartOfThread: Bool 
```

### `textContent`

The text which should be shown in a text view inside the message bubble.

``` swift
var textContent: String? 
```

### `isOnlyVisibleForCurrentUser`

A boolean value that checks if the message is visible for current user only.

``` swift
var isOnlyVisibleForCurrentUser: Bool 
```

### `lastActiveThreadParticipant`

Returns last active thread participant.

``` swift
var lastActiveThreadParticipant: _ChatUser<ExtraData.User>? 
```

### `isDeleted`

A boolean value that says if the message is deleted.

``` swift
var isDeleted: Bool 
```
