---
title: Assertions
---

A common way of highlighting unexpected behaviors in Swift is by using [assertions](https://developer.apple.com/documentation/swift/1541112-assert). 

Inside the Stream SDKs, we use wrappers around it (`log.assert`/`log.assertionFailure`). This is because we want to allow the integrators to silence those if they want to.

You can change that behavior by changing the value for `assertionsEnabled` as follows:

```
StreamRuntimeCheck.assertionsEnabled = true
```

The default value for this property is `false`

:::note
When enabling Stream assertions, the default behavior of assertions still apply:
- In playgrounds and -Onone builds (the default for Xcode’s Debug configuration): If the condition evaluates to false, stop program execution in a debuggable state after printing the message.
- In -O builds (the default for Xcode’s Release configuration), the condition is not evaluated, and there are no effects.
- In -Ounchecked builds, the condition is not evaluated, but the optimizer may assume that it always evaluates to true. Failure to satisfy that assumption is a serious programming error.

Read more [here](https://developer.apple.com/documentation/swift/1541112-assert). 
:::
