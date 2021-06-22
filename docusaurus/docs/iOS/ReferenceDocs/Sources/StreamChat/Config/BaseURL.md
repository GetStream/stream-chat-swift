---
id: baseurl 
title: BaseURL
slug: /ReferenceDocs/Sources/StreamChat/Config/baseurl
---

A struct representing base URL for `ChatClient`.

``` swift
public struct BaseURL: CustomStringConvertible 
```

## Inheritance

`CustomStringConvertible`

## Initializers

### `init(url:)`

Init with a custom server URL.

``` swift
public init(url: URL) 
```

#### Parameters

  - url: an URL

## Properties

### `usEast`

The base url for StreamChat data center located in the US East Cost.

``` swift
public static let usEast = BaseURL(urlString: "https://chat-proxy-us-east.stream-io-api.com/")!
```

### `dublin`

The base url for StreamChat data center located in Dublin.

``` swift
public static let dublin = BaseURL(urlString: "https://chat-proxy-dublin.stream-io-api.com/")!
```

### `singapore`

The base url for StreamChat data center located in Singapore.

``` swift
public static let singapore = BaseURL(urlString: "https://chat-proxy-singapore.stream-io-api.com/")!
```

### `sydney`

The base url for StreamChat data center located in Sydney.

``` swift
public static let sydney = BaseURL(urlString: "https://chat-proxy-sydney.stream-io-api.com/")!
```

### `description`

``` swift
public var description: String 
```
