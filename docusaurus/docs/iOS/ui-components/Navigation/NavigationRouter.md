
A root class for all routes in the SDK.

``` swift
open class NavigationRouter<Controller: UIViewController>: UIResponder 
```

Router objects are used to handle navigation between view controllers.

> 

## Inheritance

`UIResponder`

## Initializers

### `init(rootViewController:)`

Creates a new instance of `NavigationRouter`.

``` swift
public required init(rootViewController: Controller) 
```

#### Parameters

  - rootViewController: The view controller used as the root VC.

## Properties

### `rootViewController`

The root `UIViewController` object of this router.

``` swift
public unowned var rootViewController: Controller
```

### `rootNavigationController`

A convenience method to get the navigation controller of the root view controller.

``` swift
public var rootNavigationController: UINavigationController? 
```

### `next`

``` swift
override open var next: UIResponder? 
```
