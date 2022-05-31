//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// We accessing a deleted NSManagedObject, we need to take in consideration that all the properties are nil.
/// What happens, though, is that Objective-C provides default properties for certain types during the conversion
/// to Swift types. This is NOT the case for `Date`/`NSDate`, and that's why we need some extra treating.
///
/// If we were to define a NSManagedObject's date property as `Date`, whenever accessing it **as part of a
/// deleted object** , it would instantly crash on `Date._unconditionallyBridgeFromObjectiveC(NSDate?)`.
/// This is because it has no way to convert a nil value, to a Swift `Date` straight away.
/// Instead, when using Objective-C's `NSDate`, the treatment is a bit different (remember Objective-C? :trollface:).
/// This conversion from nil to `NSDate` does not crash on access, but instead when trying to reflect its type from
/// Swift. For example, when trying to `print()` or mirror a nil backed NSDate, methods like `swift_getObjectType` or
/// `swift_dynamicCast` get called, leading to a crash.
///
/// The intended behaviour of DBDate, which is just a typealias, is to somehow wrap NSDate into something that brings the
/// attention of who is using it, and try to convert it to a regular Date as soon as possible. Only our DTOs should have
/// properties of this type(alias), and we should limit the scope of it.
///
/// *How does `bridgeDate`work on a deleted object?*
///
/// When the conversion is from `Date` to `NSDate`, there is no issue. A `Date` cannot be backed by a nil value, so we are safe.
///
/// When the conversion is from `NSDate` to `Date` we have 2 possibilities:
/// - When `NSDate` is backed by a value:
///      No issue here, simple conversion given the values are there.
/// - When `NSDate` is backed by nil:
///     Because `NSDate`s `timeIntervalSince1970` value defaults to 0 for a nil backed `NSData`, and to a correct value /// when it
///     is backed by a real value, we use `Date(timeIntervalSince1970:)` to create the `Date`.
///
/// **How to reproduce what's happening?**
///
/// let aDate: NSDate! = nil
/// let aFalseDate = unsafeBitCast(aDate, to: NSDate.self)
///
/// String(describing: aFalseDate)               // Will not crash
/// aFalseDate.timeIntervalSince1970        // Will not crash
/// print(aFalseDate)                                   // Will crash - Internally calls `swift_getObjectType`
/// dump(aFalseDate)                                 // Will crash - Internally calls `swift_dynamicCast`
///

typealias DBDate = NSDate
extension DBDate {
    var bridgeDate: Date {
        Date(timeIntervalSince1970: timeIntervalSince1970)
    }
}

extension Date {
    var bridgeDate: DBDate {
        DBDate(timeIntervalSince1970: timeIntervalSince1970)
    }
}
