---
id: themeprovider 
title: ThemeProvider
--- 

``` swift
public protocol ThemeProvider: ComponentsProvider, AppearanceProvider 
```

## Inheritance

[`AppearanceProvider`](AppearanceProvider), [`ComponentsProvider`](ComponentsProvider)

## Default Implementations

### `uiConfig`

``` swift
@available(*, deprecated, message: "uiConfig has split into appearance and components")
    var uiConfig: UIConfig 
```
