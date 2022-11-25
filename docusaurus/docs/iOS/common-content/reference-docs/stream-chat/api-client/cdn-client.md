---
title: CDNClient
---

API client that handles working with content (for example uploading attachments)

``` swift
public protocol CDNClient 
```

## Requirements

### maxAttachmentSize

Specifies maximum attachment size in bytes.

``` swift
static var maxAttachmentSize: Int64 
```

### uploadAttachment(\_:​progress:​completion:​)

``` swift
func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<URL, Error>) -> Void
    )
```

#### Parameters

- `attachment`: An attachment to upload
- `progress`: A closure that broadcasts upload progress
- `completion`: Returns uploading result on upload completion or failure
