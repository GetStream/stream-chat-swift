
A protocol an attachment payload type has to conform in order it can be
attached to/exposed on the message.

``` swift
public protocol AttachmentPayload: Codable 
```

## Inheritance

`Codable`

## Requirements

### type

A type of resulting attachment.

``` swift
static var type: AttachmentType 
```
