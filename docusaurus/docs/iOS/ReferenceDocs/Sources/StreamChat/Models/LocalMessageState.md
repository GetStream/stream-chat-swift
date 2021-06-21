---
id: localmessagestate 
title: LocalMessageState
slug: referencedocs/sources/streamchat/models/localmessagestate
---

A possible additional local state of the message. Applies only for the messages of the current user.

``` swift
public enum LocalMessageState: String 
```

## Inheritance

`String`

## Enumeration Cases

### `pendingSync`

The message is waiting to be synced.

``` swift
case pendingSync
```

### `syncing`

The message is currently being synced

``` swift
case syncing
```

### `syncingFailed`

Syncing of the message failed after multiple of tries. The system is not trying to sync this message anymore.

``` swift
case syncingFailed
```

### `pendingSend`

The message is waiting to be sent.

``` swift
case pendingSend
```

### `sending`

The message is currently being sent to the servers.

``` swift
case sending
```

### `sendingFailed`

Sending of the message failed after multiple of tries. The system is not trying to send this message anymore.

``` swift
case sendingFailed
```

### `deleting`

The message is waiting to be deleted.

``` swift
case deleting
```

### `deletingFailed`

Deleting of the message failed after multiple of tries. The system is not trying to delete this message anymore.

``` swift
case deletingFailed
```
