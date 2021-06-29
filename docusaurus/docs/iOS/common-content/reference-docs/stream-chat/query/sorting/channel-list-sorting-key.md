---
title: ChannelListSortingKey
---

`ChannelListSortingKey` is keys by which you can get sorted channels after query.

``` swift
public enum ChannelListSortingKey: String, SortingKey 
```

## Inheritance

[`SortingKey`](../sorting-key), `String`

## Enumeration Cases

### `` `default` ``

The default sorting is by the last massage date or a channel created date. The same as by `updatedDate`.

``` swift
case `default` = "defaultSortingAt"
```

### `createdAt`

Sort channels by date they were created.

``` swift
case createdAt
```

### `updatedAt`

Sort channels by date they were updated.

``` swift
case updatedAt
```

### `lastMessageAt`

Sort channels by the last message date..

``` swift
case lastMessageAt
```

### `memberCount`

Sort channels by number of members.

``` swift
case memberCount
```

### `cid`

Sort channels by `cid`.
**Note**:​ This sorting option can extend your response waiting time if used as primary one.

``` swift
case cid
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
```
