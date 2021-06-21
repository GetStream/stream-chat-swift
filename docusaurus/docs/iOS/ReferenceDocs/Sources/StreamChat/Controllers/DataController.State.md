---
id: datacontroller.state 
title: DataController.State
--- 

Describes the possible states of `DataController`

``` swift
public enum State: Equatable 
```

## Inheritance

`Equatable`

## Enumeration Cases

### `initialized`

The controller is created but no data fetched.

``` swift
case initialized
```

### `localDataFetched`

The controllers already fetched local data if any.

``` swift
case localDataFetched
```

### `localDataFetchFailed`

The controller failed to fetch local data.

``` swift
case localDataFetchFailed(ClientError)
```

### `remoteDataFetched`

The controller fetched remote data.

``` swift
case remoteDataFetched
```

### `remoteDataFetchFailed`

The controller failed to fetch remote data.

``` swift
case remoteDataFetchFailed(ClientError)
```
