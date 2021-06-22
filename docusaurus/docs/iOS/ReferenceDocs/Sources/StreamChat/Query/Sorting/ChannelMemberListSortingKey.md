---
id: channelmemberlistsortingkey 
title: ChannelMemberListSortingKey
slug: /ReferenceDocs/Sources/StreamChat/Query/Sorting/channelmemberlistsortingkey
---

`ChannelMemberListSortingKey` describes the keys by which you can get sorted channel members after query.

``` swift
public enum ChannelMemberListSortingKey: String, SortingKey 
```

## Inheritance

[`SortingKey`](SortingKey), `String`

## Enumeration Cases

### `createdAt`

``` swift
case createdAt = "memberCreatedAt"
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
```
