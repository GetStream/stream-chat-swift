---
title: FilterValue
---

A protocol to which all values that can be used as `Filter` values conform.

``` swift
public protocol FilterValue: Encodable 
```

Only types representing text, numbers, booleans, dates, and other filters can be on the "right-hand" side of `Filter`.

## Inheritance

`Encodable`
