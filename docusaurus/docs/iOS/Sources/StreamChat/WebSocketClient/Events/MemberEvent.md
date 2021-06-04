
A protocol for any `MemberEvent` where it has a `member`, and `channel` payload.

``` swift
public protocol MemberEvent: Event 
```

## Inheritance

[`Event`](Event)

## Requirements

### memberUserId

``` swift
var memberUserId: UserId 
```

### cid

``` swift
var cid: ChannelId 
```
