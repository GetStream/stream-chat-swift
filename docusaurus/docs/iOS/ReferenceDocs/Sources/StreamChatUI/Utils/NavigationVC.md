---
id: navigationvc 
title: NavigationVC
slug: /ReferenceDocs/Sources/StreamChatUI/Utils/navigationvc
---

The navigation controller with navigation bar of `ChatNavigationBar` type.

``` swift
open class NavigationVC: UINavigationController 
```

## Inheritance

`UINavigationController`

## Initializers

### `init(rootViewController:navigationBarClass:toolbarClass:)`

``` swift
public required init(
        rootViewController: UIViewController,
        navigationBarClass: ChatNavigationBar.Type = ChatNavigationBar.self,
        toolbarClass: AnyClass? = nil
    ) 
```

### `init?(coder:)`

``` swift
public required init?(coder aDecoder: NSCoder) 
```
