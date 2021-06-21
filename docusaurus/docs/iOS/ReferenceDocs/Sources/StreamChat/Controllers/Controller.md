---
id: controller 
title: Controller
--- 

A protocol to which all controllers conform to.

``` swift
public protocol Controller 
```

This protocol is not meant to be adopted by your custom types.

## Requirements

### callbackQueue

The queue which is used to perform callback calls

``` swift
var callbackQueue: DispatchQueue 
```
