//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

// last_updated, last_message_at, updated_at, created_at, member_count, unread_count or has_unread

class Example {
    let channels: [ChatChannel] = []

    func sortWithDynamicMember(with sorting: [Sorting<ChannelListSortingKey>]) -> [ChatChannel] {
        channels.sorted { lhs, rhs in
            for sort in sorting {
                let stringKeyPath = sort.key.rawValue
                let lhsValue = lhs[dynamicMember: stringKeyPath] ?? ""
                let rhsValue = rhs[dynamicMember: stringKeyPath] ?? ""

                if sort.isAscending, lhsValue < rhsValue {
                    return true
                } else if !sort.isAscending, lhsValue > rhsValue {
                    return true
                } else {
                    continue
                }
            }

            return false
        }
    }

    struct SortValue<T> {
        let keyPath: PartialKeyPath<T>
        let isAscending: Bool
    }

    func sortWithKeyPath(with sorting: [SortValue<ChatChannel>]) -> [ChatChannel] {
        func evaluate(lhs: Any?, rhs: Any?, isAscending: Bool) -> Bool {
            if lhs == nil, rhs != nil, !isAscending {
                return true
            } else if lhs != nil, rhs == nil, isAscending {
                return true
            }

            if let lString = lhs as? String, let rString = rhs as? String {
                return isAscending ? lString < rString : lString > rString
            } else if let lInt = lhs as? Int, let rInt = rhs as? Int {
                return isAscending ? lInt < rInt : lInt > rInt
            } else if let lDouble = lhs as? Double, let rDouble = rhs as? Double {
                return isAscending ? lDouble < rDouble : lDouble > rDouble
            } else if let lDate = lhs as? Date, let rDate = rhs as? Date {
                return isAscending ? lDate < rDate : lDate > rDate
            } else if let lBool = lhs as? Bool, let rBool = rhs as? Bool {
                return isAscending ? !lBool && rBool : lBool && !rBool
            }

            return false
        }

        return channels.sorted { lhs, rhs in
            for sort in sorting {
                let lhsValue = lhs[keyPath: sort.keyPath]
                let rhsValue = rhs[keyPath: sort.keyPath]

                if sort.isAscending, evaluate(lhs: lhs, rhs: rhs, isAscending: sort.isAscending) {
                    return true
                } else if !sort.isAscending, evaluate(lhs: lhs, rhs: rhs, isAscending: sort.isAscending) {
                    return true
                } else {
                    continue
                }
            }

            return false
        }
    }
}

extension ChatChannel {
    // This method is meant to only be used for sorting functionality.
    subscript(dynamicMember member: String) -> String? {
        switch member {
        case "cid":
            return cid.rawValue
        case "name":
            return name
        case "type":
            return type.rawValue
        case "lastMessageAt":
            return lastMessageAt?.sortValue
        case "createdBy":
            return createdBy?.id
        case "createdAt":
            return createdAt.sortValue
        case "updatedAt":
            return updatedAt.sortValue
        case "deletedAt":
            return deletedAt?.sortValue
        case "truncatedAt":
            return truncatedAt?.sortValue
        case "isHidden":
            return isHidden.sortValue
        case "isFrozen":
            return isFrozen.sortValue
        case "isMuted":
            return isMuted.sortValue
        case "isDeleted":
            return isDeleted.sortValue
        case "isDirectMessageChannel":
            return isDirectMessageChannel.sortValue
        case "isUnread":
            return isUnread.sortValue
        case "memberCount":
            return memberCount.sortValue
        case "watcherCount":
            return watcherCount.sortValue
        case "membership":
            return membership?.memberRole.rawValue
        case "unreadCount":
            return unreadCount.messages.sortValue
        case "lastMessageFromCurrentUser":
            return lastMessageFromCurrentUser?.createdAt.sortValue
        case "team":
            return team
        default:
            break
        }

        // Does not work with nested values (eg. "scope.score" -> `extraData: { scope : { score : 1 }}`)
        if let value = extraData[member] {
            return value.sortValue
        }

        return nil
    }
}

private extension RawJSON {
    var sortValue: String? {
        if let number = numberValue {
            return number.sortValue
        } else if let string = stringValue {
            return string
        } else if let bool = boolValue {
            return bool.sortValue
        } else {
            return nil
        }
    }
}

private extension Bool {
    var sortValue: String { self ? "0" : "1" }
}

private extension Int {
    var sortValue: String { "\(self)" }
}

private extension Double {
    var sortValue: String { "\(self)" }
}

private extension Date {
    var sortValue: String { description }
}
