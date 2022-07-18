---
title: Extra Data
---

Extra Data is additional information that can be added to the default data of Stream. It is a dictionary of key-value pairs that can be attached to messages, users, channels, and pretty much almost every domain model in the Stream SDK.

On iOS, the Extra Data is represented by the following dictionary, `[String: RawJSON]`. The `RawJSON` is an enum that can be represented by different types of values. It can be a String, Number, Boolean, Array, Dictionary, or null. In the end, this is to make the dictionary strongly typed so that it is more safe and easier to use. The code snippet below shows the simplified implementation of `RawJSON`.

```swift
indirect enum RawJSON: Codable, Hashable {
    case number(Double)
    case string(String)
    case bool(Bool)
    case dictionary([String: RawJSON])
    case array([RawJSON])
}
```

## Adding Extra Data

Adding extra data can be done through the Server-Side SDKs or through the client SDKs. In the iOS Stream Chat SDK, you can add extra data when creating/updating a message, user channel, or any other model through our controllers.

As a simple example, let's see how you can add a new email field to the current logged user.

```swift
let currentUserController = client.currentUserController()
currentUserController.updateUserData(
    name: "John Doe",
    imageURL: nil,
    userExtraData: ["email": .string("john.doe@example.com")],
    completion: nil
)
```

For a more complete example now, let's imagine you want to add a ticket information to a message.

```swift
let extraData: [String: RawJSON] = [
    "ticket": .dictionary([
        "name": .string("Rock Concert"),
        "price": .double(20)
    ])
]
let channelController = client.channelController(for: yourChannelId)
channelController.createNewMessage(text: "A new message", extraData: extraData)
```

:::tip
Since `RawJSON` implements `ExpressibleByDictionaryLiteral`, you can simplify the example above like this:
```swift
let extraData: [String: RawJSON] = [
    "ticket": [
        "name": .string("Rock Concert"),
        "price": .double(20)
    ])
]
```
***Note:*** This is only available on 4.19.0+ versions of the SDK.
:::

## Reading Extra Data

All of the most important domain models in the SDK have a `extraData` property that you can read the additional information that is added.

Since the 4.19.0 version of the SDK you can read extra data properties very easily. The following code snippet shows how to get an email from a user's extra data.

```swift
let email = user.extraData["email"]?.stringValue ?? ""
print(email)
```

If you are using an SDK version below 4.19.0, this how you would read the email from the extra data:
```swift
let extraData = user.extraData
var email: String {
    guard case .string(let value) = extraData["email"] else { return "" }
    return value
}
```

:::tip
In order to access the email even more easily, you can extend our models to provide an extra property, in this case, you can add an `email` property to the `ChatUser` model like this:
```swift
extension ChatUser {
    var email: String? {
        extraData["email"]?.stringValue
    }
}
```
:::

To see how you can get data with different types from extra data, we can pick the example of the ticket information again and see how you can get it from extra data.

```swift
let ticket = message.extraData["ticket"]?.dictionaryValue
let name = ticket?["name"]?.stringValue ?? ""
let price = ticket?["price"]?.doubleValue ?? 0.0
// This is also valid:
let name = message.extraData["ticket"]?["name"]?.stringValue ?? ""
let price = message.extraData["ticket"]?["price"]?.doubleValue ?? 0.0
```

As you can see above, each type of value can be easily accessible from an extra data property. The SDK will try to convert the raw type to a strongly typed value and return it if the property exists, and if the type is correct. Below is the list of all values supported:

- `stringValue: String?`
- `numberValue: Double?`
- `boolValue: Bool?`
- `dictionaryValue: [String: RawJSON]?`
- `arrayValue: [RawJSON]?`
- `stringArrayValue: [String]?`
- `numberArrayValue: [Double]?`
- `boolArrayValue: [Bool]?`

## Advanced Example

Most likely your app has more complex data structures compared to the ones described above. So, let's see an example of how you could map your domain models to extra data and vice-versa by imagining that a message can have details of a booking flight.

```swift
struct BookingFlight {
    let flightNumber: Double
    let departureDate: Date
    let arrivalDate: Date
    let price: Double
    let passengers: [Passenger]
    let destinations: [String]
}

struct Passenger {
    let name: String
    let age: Int
}
```

From the example above, now let's see how we can provide Extra Data mappings for these models:

```swift
extension Passenger {
    init?(extraData: [String: RawJSON]) {
        guard let name = extraData["name"]?.stringValue else { return nil }
        guard let age = extraData["age"]?.numberValue else { return nil }
        self.name = name
        self.age = Int(age)
    }

    func toExtraData() -> [String: RawJSON] {
        [
            "name": .string(name),
            "age": .number(Double(age))
        ]
    }
}

extension BookingFlight {
    init?(extraData: [String: RawJSON]) {
        guard let flightNumber = extraData["flightNumber"]?.numberValue else { return nil }
        guard let price = extraData["price"]?.numberValue else { return nil }
        guard let departureDate = extraData["departureDate"]?.stringValue else { return nil }
        guard let arrivalDate = extraData["arrivalDate"]?.stringValue else { return nil }
        let destinations = extraData["destinations"]?.stringArrayValue ?? []
        let passengers = extraData["passengers"]?.arrayValue?
            .compactMap(\.dictionaryValue)
            .compactMap(Passenger.init(extraData:))
            ?? []

        self.flightNumber = flightNumber
        self.price = price
        self.departureDate = StreamDateFormatter.date(from: departureDate)
        self.arrivalDate = StreamDateFormatter.date(from: arrivalDate)
        self.destinations = destinations
        self.passengers = passengers
    }

    func toExtraData() -> [String: RawJSON] {
        [
            "flightNumber": .number(flightNumber),
            "departureDate": .string(
                StreamDateFormatter.dateString(from: departureDate)
            ),
            "arrivalDate": .string(
                StreamDateFormatter.dateString(from: arrivalDate)
            ),
            "price": .double(price),
            "destinations": .array(destinations.map(RawJSON.string)),
            "passengers": .array(
                passengers
                    .map( { $0.toExtraData() })
                    .map(RawJSON.dictionary)
            )
        ]
    }
}
```

Then, we can extend the `ChatMessage` model and add a `bookingFlight` property:

```swift
extension ChatMessage {
    var bookingFlight: BookingFlight? {
        guard let extraData = extraData["flight"]?.dictionaryValue else { return nil }
        return BookingFlight(extraData: extraData)
    }
}
```

Finally, if we want to create a message with the booking flight information, we can do it like this:

```swift
let bookingFlight: BookingFlight = ...
let extraData: [String: RawJSON] = ["flight": bookingFlight.toExtraData()]
let channelController = client.channelController(for: yourChannelId)
channelController.createNewMessage(text: "A new message", extraData: extraData)
```