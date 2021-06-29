---
title: AttachmentUploadingState
---

A type representing the uploading state for attachments that require prior uploading.

``` swift
public struct AttachmentUploadingState: Equatable 
```

## Inheritance

`Equatable`

## Properties

### `localFileURL`

The local file URL that is being uploaded.

``` swift
public let localFileURL: URL
```

### `state`

The uploading state.

``` swift
public let state: LocalAttachmentState
```

### `file`

The information about file size/mimeType.

``` swift
public let file: AttachmentFile
```
