---
id: localattachmentstate 
title: LocalAttachmentState
slug: referencedocs/sources/streamchat/models/attachments/localattachmentstate
---

A local state of the attachment. Applies only for attachments linked to the new messages sent from current device.

``` swift
public enum LocalAttachmentState: Hashable 
```

## Inheritance

`Hashable`

## Enumeration Cases

### `pendingUpload`

The attachment is waiting to be uploaded.

``` swift
case pendingUpload
```

### `uploading`

The attachment is currently being uploaded. The progress in \[0, 1\] range.

``` swift
case uploading(progress: Double)
```

### `uploadingFailed`

Uploading of the message failed. The system will not trying to upload this attachment anymore.

``` swift
case uploadingFailed
```

### `uploaded`

The attachment is successfully uploaded.

``` swift
case uploaded
```
