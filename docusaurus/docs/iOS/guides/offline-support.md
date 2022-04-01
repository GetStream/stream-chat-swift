---
title: Offline Support
---

Offline support comes in 4 different aspects:

- Connection Recovery
- Events Recovery
- Queue Offline Actions (optional, enabled by default)
- Keeping the DB on disk (optional, enabled by default)

### Connection Recovery:

It is really important to make sure that the app properly reconnects after a downtime, independently of what was the cause of it. It can happen that you backgrounded the app, you lost connection or maybe it was killed by yourself or the system.

We are listening to the app's lifecycle to make sure we perform the right set of actions to bring you up online as soon as possible


### Events Recovery:

Whenever the app is not foregrounded and connected to the internet, there are likely other actions performed by other users. Especially in a Chat app, there are tons of events that can happen while you were offline.

To overcome this situation, we are fetching all the events that happened since the end of your last online session up until the moment you foreground the app, we are processing them and making sure the app accordingly reflects those.

This happens without you needing to do anything.


### Queued Offline Actions:

You may be in the subway, and you are trying to send a message, but suddenly your connection drops. We make sure that this action is queued, and sent whenever you come back offline.
Even if you/the system kills the app, we make sure the request is sent in your next session.

These are the actions that support offline queuing:
- Send message
- Edit message
- Delete message
- Add reaction
- Delete reaction

### Keeping the DB on disk

By making sure that the DB stays on disk, we can guarantee that the data stays across sessions. This helps when it comes to perception. Having fewer loading states or blank pages is more engaging to the users.


## Opting out

As mentioned above, you can opt-out for:
- Queue Offline Actions
- Keeping the DB on disk

To do that, you can just modify your configuration as follows:

```swift
var config = ChatClientConfig(apiKey: .init("<# Your API Key Here #>"))        
config.isLocalStorageEnabled = false
```
