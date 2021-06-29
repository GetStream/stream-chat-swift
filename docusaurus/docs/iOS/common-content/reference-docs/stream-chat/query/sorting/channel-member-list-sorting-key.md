---
title: ChannelMemberListSortingKey
---

`ChannelMemberListSortingKey` describes the keys by which you can get sorted channel members after query.

``` swift
public enum ChannelMemberListSortingKey: String, SortingKey 
```

## Inheritance

[`SortingKey`](../sorting-key), `String`

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
