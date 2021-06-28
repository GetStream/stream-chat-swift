---
title: ThemeProvider
---

``` swift
public protocol ThemeProvider: ComponentsProvider, AppearanceProvider 
```

## Inheritance

[`AppearanceProvider`](appearance-provider.md), [`ComponentsProvider`](components-provider.md)

## Default Implementations

### `uiConfig`

``` swift
@available(*, deprecated, message: "uiConfig has split into appearance and components")
    var uiConfig: UIConfig 
```
