---
id: apikey 
title: APIKey
slug: /ReferenceDocs/Sources/StreamChat/Config/apikey
---

A struct representing an API key of the chat app.

``` swift
public struct APIKey: Equatable 
```

An API key can be obtained by registering on \[our website\](https://getstream.io/chat/trial/).

## Inheritance

`Equatable`

## Initializers

### `init(_:)`

Creates a new `APIKey` from the provided string. Fails, if the string is empty.

``` swift
public init(_ apiKeyString: String) 
```

> 

## Properties

### `apiKeyString`

The string representation of the API key

``` swift
public let apiKeyString: String
```
