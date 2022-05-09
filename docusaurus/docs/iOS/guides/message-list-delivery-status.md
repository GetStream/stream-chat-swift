---
title: Message Delivery Status
---

import Digraph  from '../common-content/digraph.jsx'

For messages sent by the current user, the delivery status is shown in the message cell.

Delivery status can be one of the following:
- **pending send** (when a message is queued to be sent)
- **sending failed** (when message sending has failed)
- **sent** (when a message is sent but not yet seen by any channel member)
- **read** (when a message is seen by 1 or more channel members)

For group channels with more than 2 members, the number of members who have seen the message is shown next to the read indicator.

| Pending send | Sending failed | Sent | Read | Read by many |
| ------------ | -------------- | ---- | ---- | ------------ |
| <img src={require("../assets/message-delivery-state-pending-send.png").default}/> | <img src={require("../assets/message-delivery-state-sending-failed.png").default}/> | <img src={require("../assets/message-delivery-state-sent.png").default}/> | <img src={require("../assets/message-delivery-state-read.png").default}/> | <img src={require("../assets/message-delivery-state-read-group.png").default}/> |

### Delivery Status Transitions

The diagram below shows how message delivery state changes.
<Digraph>{ `
    pending_send -> sent
    pending_send -> sending_failed
    sending_failed -> pending_send
    sent -> read
    read -> sent
`
}</Digraph>

#### Pending send
When user taps send button in message composer, the message is saved to local database and queued for sending. When it happens, message appears in the channel in `pending send` delivery status.

#### Pending send -> Sending failed
When message sending fails (e.g. because of missing Internet connection), a transition from `pending send` to `sending failed` state happens. In that case, delivery status gets hidden and error indicator appears.

#### Sending failed -> Pending send
If message sending has failed the long-pressing the message shows a pop-up with **Resend** action available. When user initiates message resend, the `sending failed` -> `pending send` transition happens.

#### Pending send -> Sent
When message sending succeeds, the state goes from `pending send` to `sent` and single checkmark appears. At this moment, channel members receive a web-socket event that the new message is posted to the channel which increments unread messages count for the channel.

#### Sent -> Read
When a channel member opens the channel / scrolls the channel to bottom and sees the message, the delivery state moves from `sent` -> `read` and double-checkmark is shown. 

Another case is when a new member is added to the channel. When it happens, all messages in the channel get `read` by this member.

#### Read -> Sent
The transition happens when a message is read by a single channel member when this member is removed from the channel. In that case, message moves back to `sent` state.

:::note
If `read_events` are turned OFF for the channel, delivery indicators are hidden.
:::

:::note
To know more on how to customize delivery indicator UI check out [Customize Message Delivery Status](./customize-message-delivery-status.md) guide.
:::
