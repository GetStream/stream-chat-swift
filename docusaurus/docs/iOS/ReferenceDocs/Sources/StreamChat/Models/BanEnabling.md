
An option to enable ban users.

``` swift
public enum BanEnabling 
```

## Enumeration Cases

### `disabled`

Disabled for everyone.

``` swift
case disabled
```

### `enabled`

Enabled for everyone.
The default timeout in minutes until the ban is automatically expired.
The default reason the ban was created.

``` swift
case enabled(timeoutInMinutes: Int?, reason: String?)
```

### `enabledForModerators`

Enabled for channel members with a role of moderator or admin.
The default timeout in minutes until the ban is automatically expired.
The default reason the ban was created.

``` swift
case enabledForModerators(timeoutInMinutes: Int?, reason: String?)
```

## Properties

### `timeoutInMinutes`

The default timeout in minutes until the ban is automatically expired.

``` swift
public var timeoutInMinutes: Int? 
```

### `reason`

The default reason the ban was created.

``` swift
public var reason: String? 
```

## Methods

### `isEnabled(for:)`

Returns true is the ban is enabled for the channel.

``` swift
public func isEnabled(for channel: ChatChannel) -> Bool 
```

#### Parameters

  - channel: a channel.
