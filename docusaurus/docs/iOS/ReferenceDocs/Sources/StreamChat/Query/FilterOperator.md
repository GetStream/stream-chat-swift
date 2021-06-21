---
id: filteroperator 
title: FilterOperator
--- 

An enum with possible operators to use in filters.

``` swift
public enum FilterOperator: String 
```

## Inheritance

`String`

## Enumeration Cases

### `equal`

Matches values that are equal to a specified value.

``` swift
case equal = "$eq"
```

### `notEqual`

Matches all values that are not equal to a specified value.

``` swift
case notEqual = "$ne"
```

### `greater`

Matches values that are greater than a specified value.

``` swift
case greater = "$gt"
```

### `greaterOrEqual`

Matches values that are greater than a specified value.

``` swift
case greaterOrEqual = "$gte"
```

### `less`

Matches values that are less than a specified value.

``` swift
case less = "$lt"
```

### `lessOrEqual`

Matches values that are less than or equal to a specified value.

``` swift
case lessOrEqual = "$lte"
```

### `` `in` ``

Matches any of the values specified in an array.

``` swift
case `in` = "$in"
```

### `notIn`

Matches none of the values specified in an array.

``` swift
case notIn = "$nin"
```

### `query`

Matches values by performing text search with the specified value.

``` swift
case query = "$q"
```

### `autocomplete`

Matches values with the specified prefix.

``` swift
case autocomplete = "$autocomplete"
```

### `exists`

Matches values that exist/don't exist based on the specified boolean value.

``` swift
case exists = "$exists"
```

### `and`

Matches all the values specified in an array.

``` swift
case and = "$and"
```

### `or`

Matches at least one of the values specified in an array.

``` swift
case or = "$or"
```

### `nor`

Matches none of the values specified in an array.

``` swift
case nor = "$nor"
```
