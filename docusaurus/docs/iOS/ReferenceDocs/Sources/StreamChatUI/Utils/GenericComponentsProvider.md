
``` swift
public protocol GenericComponentsProvider: AnyObject 
```

## Inheritance

`AnyObject`

## Requirements

### register(components:​)

``` swift
func register<T: ExtraDataTypes>(components: _Components<T>)
```

### components(\_:​)

``` swift
func components<T: ExtraDataTypes>(_ extraDataType: T.Type) -> _Components<T>
```

### componentsDidRegister()

``` swift
func componentsDidRegister()
```
