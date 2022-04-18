---
title: Dependency Injection
---

For injecting dependencies in the SwiftUI SDK, we are using an approach based on [this article](https://www.avanderlee.com/swift/dependency-injection/). It works similarly to the @Environment in SwiftUI, but it also allows access to the dependencies in non-view related code.

When you initialize the SDK (by creating the `StreamChat` object), all the dependencies are created too, and you can use them anywhere in your code. In order to access a particular type, you need to use the `@Injected(\.keyPath)` property wrapper:

```swift
@Injected(\.chatClient) var chatClient
@Injected(\.fonts) var fonts
@Injected(\.colors) var colors
@Injected(\.images) var images
@Injected(\.utils) var utils
```

### Extending the DI with Custom Types

In some cases, you might also need to extend our DI mechanism with your own types. For example, you may want to be able to access your custom types like this:

```swift
@Injected(\.customType) var customType
```  

In order to achieve this, you first need to define your own `InjectionKey`, and define it's currentValue, which basically creates the new instance of your type.

```swift
class CustomType {
	// your custom logic here
}

struct CustomInjectionKey: InjectionKey {
    static var currentValue: CustomType = CustomType()
}
```

Next, you need to extend our `InjectedValues` with your own custom type, by defining its getter and setter.

```swift
extension InjectedValues {
    /// Provides access to the `CustomType` instance in the views and view models.
    var customType: CustomType {
        get {
            Self[CustomInjectionKey.self]
        }
        set {
            Self[CustomInjectionKey.self] = newValue
        }
    }
}
```

With these few simple steps, you can now access your custom functionality in both your app code and in your custom implementations of the views used throughout the SDK. 