
### `allEventsPublisher`

A publisher emitting a new value every time an event is observed.

``` swift
public var allEventsPublisher: AnyPublisher<Event, Never> 
```

### `observableObject`

A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.

``` swift
public var observableObject: ObservableObject 
```

### `callbackQueue`

A callback queue on which delegate methods are invoked.

``` swift
public var callbackQueue: DispatchQueue = .main
```

### `delegate`

A delegate the controller notifies about the updates.

``` swift
public var delegate: EventsControllerDelegate? 
```

## Methods

### `eventPublisher(_:)`

Returns a publisher emitting a new value every time event of the given type is observed.

``` swift
public func eventPublisher<T: Event>(_ eventType: T.Type) -> AnyPublisher<T, Never> 
```

#### Parameters

  - eventType: An event type that will be observed.

#### Returns

