---
title: DataStoreProvider
---

Types conforming to this protocol automatically exposes public `dataStore` variable.

``` swift
public protocol DataStoreProvider 
```

## Default Implementations

### `dataStore`

`DataStore` provide access to all locally available model objects based on their id.

``` swift
public var dataStore: DataStore 
```

## Requirements

### client

``` swift
var client: ChatClient 
```
