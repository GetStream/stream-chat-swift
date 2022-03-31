//
//  ExtraDataHelper.swift
//  StreamChat
//
//  Created by Ajay Ghodadra on 04/02/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public extension Dictionary where Key == String, Value == RawJSON {
    func getExtraData(key: String) -> [String: RawJSON]? {
        if let extraData = self[key] {
            switch extraData {
            case .dictionary(let dictionary):
                return dictionary
            default:
                return nil
            }
        } else {
            return nil
        }
    }
    
    func getExtraDataArray(key: String) -> [RawJSON]? {
        if let extraData = self[key] {
            switch extraData {
            case .array(let array):
                return array
            default:
                return nil
            }
        } else {
            return nil
        }
    }
}

// MARK: - DAO
public extension Dictionary where Key == String, Value == RawJSON {
    var minimumContribution: String? {
        if let minimumContribution = self["minimumContribution"] {
            return fetchRawData(raw: minimumContribution) as? String
        } else {
            return nil
        }
    }

    var charityThumb: String? {
        if let charityThumb = self["charityThumb"] {
            return fetchRawData(raw: charityThumb) as? String
        } else {
            return nil
        }
    }

    var safeAddress: String? {
        if let charityThumb = self["safeAddress"] {
            return fetchRawData(raw: charityThumb) as? String
        } else {
            return nil
        }
    }

    var daoName: String? {
        if let daoName = self["daoName"] {
            return fetchRawData(raw: daoName) as? String
        } else {
            return nil
        }
    }

    var masterWalletAddress: String? {
        if let masterWalletAddress = self["masterWalletAddress"] {
            return fetchRawData(raw: masterWalletAddress) as? String
        } else {
            return nil
        }
    }

    var daoExpireDate: String? {
        if let daoExpireDate = self["daoExpireDate"] {
            return fetchRawData(raw: daoExpireDate) as? String
        } else {
            return nil
        }
    }

    var daoJoinLink: String? {
        if let daoJoinLink = self["daoJoinLink"] {
            return fetchRawData(raw: daoJoinLink) as? String
        } else {
            return nil
        }
    }

    var daoDescription: String? {
        if let daoDescription = self["daoDescription"] {
            return fetchRawData(raw: daoDescription) as? String
        } else {
            return nil
        }
    }

    var daoGroupCreator: String? {
        if let daoGroupCreator = self["groupCreator"] {
            return fetchRawData(raw: daoGroupCreator) as? String
        } else {
            return nil
        }
    }

    var signers: [String] {
        if let arrSigners = self["signers"] {
            let rawJson = fetchRawData(raw: arrSigners) as? [RawJSON] ?? [RawJSON]()
            return rawJson.map({ fetchRawData(raw: $0) as? String ?? ""})
        } else {
            return []
        }
    }
}

// MARK: - Admin Message
public extension Dictionary where Key == String, Value == RawJSON {
    var adminMessage: String? {
        guard let adminMessage = getExtraData(key: "adminMessage") else {
            return nil
        }
        if let strMessage = adminMessage["adminMessage"] {
            return fetchRawData(raw: strMessage) as? String
        } else {
            return nil
        }
    }
    var adminMessageMembers: [String: RawJSON]? {
        guard let adminMessage = getExtraData(key: "adminMessage") else {
            return nil
        }
        if let userIDs = adminMessage["members"] {
            return fetchRawData(raw: userIDs) as? [String: RawJSON]
        } else {
            return nil
        }
    }
    var adminMessageType: AdminMessageType {
        if let messageType = self["messageType"] {
            let rawValue = fetchRawData(raw: messageType) as? String ?? ""
            return AdminMessageType(rawValue: rawValue) ?? .none
        } else {
            return .none
        }
    }

    var daoAdmins: [[String: Any]] {
        var arrOut: [[String: Any]] = []
        if let admin = self["adminMessage"] {
            let rawJson = fetchRawData(raw: admin) as? [String: RawJSON] ?? [String: RawJSON]()
            if rawJson.keys.contains("adminMessage") {
                let arrAdmins = fetchRawData(raw: rawJson["adminMessage"]!) as? [RawJSON] ?? [RawJSON]()
                for admin in arrAdmins {
                    let dictAdmin = fetchRawData(raw: admin) as? [String: RawJSON] ?? [String: RawJSON]()
                    print(dictAdmin)
                    var dictOut: [String: Any] = [:]
                    if dictAdmin.keys.contains("signerName") {
                        dictOut["signerName"] = fetchRawData(raw: dictAdmin["signerName"]!) as? String ?? ""
                    }
                    if dictAdmin.keys.contains("signerUserId") {
                        dictOut["signerUserId"] = fetchRawData(raw: dictAdmin["signerUserId"]!) as? String ?? ""
                    }
                    arrOut.append(dictOut)
                }
                return arrOut
            } else {
                return arrOut
            }
            return arrOut
        } else {
            return arrOut
        }
    }
}

// MARK: - Normal Channel

public extension Dictionary where Key == String, Value == RawJSON {
    var channelDescription: String? {
        if let channelDescription = self[kExtraDataChannelDescription] {
            return fetchRawData(raw: channelDescription) as? String
        } else {
            return nil
        }
    }
    
    var isTreasureGroup: Bool {
        if let isTreasureGroup = self["isTreasureGroup"] {
            return fetchRawData(raw: isTreasureGroup) as? Bool ?? false
        } else {
            return false
        }
    }
}

// MARK: - RedPacketAmountBubble txId
public extension Dictionary where Key == String, Value == RawJSON {
    var txId: String? {
        if let txId = self["txId"] {
            return fetchRawData(raw: txId) as? String
        } else {
            return nil
        }
    }
}

// MARK: - Announcement
public extension Dictionary where Key == String, Value == RawJSON {
    var tag: [String]? {
        guard let tags = getExtraDataArray(key: "tags") else {
            return nil
        }
        return tags.map { fetchRawData(raw: $0) as? String ?? "" }
    }
    
    var cta: String? {
        if let ctaStr = self["cta"] {
            return fetchRawData(raw: ctaStr) as? String
        } else {
            return nil
        }
    }

    var ctaData: String? {
        if let ctaDataStr = self["cta_data"] {
            return fetchRawData(raw: ctaDataStr) as? String
        } else {
            return nil
        }
    }
}

// MARK: - RedPacket PickUp Bubble
public extension Dictionary where Key == String, Value == RawJSON {
    private var redPacketExtraData: [String: RawJSON] {
        if let extraData = self["redPacketPickup"] {
            switch extraData {
            case .dictionary(let dictionary):
                return dictionary
            default:
                return [:]
            }
        } else {
            return [:]
        }
    }

    var redPacketTitle: String? {
        if let title = redPacketExtraData["title"] {
            return fetchRawData(raw: title) as? String
        } else {
            return nil
        }
    }

    var redPacketMyName: String? {
        if let myName = redPacketExtraData["myName"] {
            return fetchRawData(raw: myName) as? String
        } else {
            return nil
        }
    }

    var redPacketMyWalletAddress: String? {
        if let myWalletAddress = redPacketExtraData["myWalletAddress"] {
            return fetchRawData(raw: myWalletAddress) as? String
        } else {
            return nil
        }
    }

    var redPacketMyImageUrl: String? {
        if let myImageUrl = redPacketExtraData["myImageUrl"] {
            return fetchRawData(raw: myImageUrl) as? String
        } else {
            return nil
        }
    }

    var redPacketChannelUsers: String? {
        if let channelUsers = redPacketExtraData["channelUsers"] {
            return fetchRawData(raw: channelUsers) as? String
        } else {
            return nil
        }
    }

    var redPacketAmount: String? {
        if let amount = redPacketExtraData["amount"] {
            return fetchRawData(raw: amount) as? String
        } else {
            return nil
        }
    }

    var redPacketChannelId: String? {
        if let channelId = redPacketExtraData["channelId"] {
            return fetchRawData(raw: channelId) as? String
        } else {
            return nil
        }
    }

    var redPacketParticipantsCount: String? {
        if let participantsCount = redPacketExtraData["participantsCount"] {
            return fetchRawData(raw: participantsCount) as? String
        } else {
            return nil
        }
    }

    var redPacketMinOne: String? {
        if let minOne = redPacketExtraData["minOne"] {
            return fetchRawData(raw: minOne) as? String
        } else {
            return nil
        }
    }

    var redPacketMaxOne: String? {
        if let maxOne = redPacketExtraData["maxOne"] {
            return fetchRawData(raw: maxOne) as? String
        } else {
            return nil
        }
    }

    var redPacketEndTime: String? {
        if let endTime = redPacketExtraData["endTime"] {
            return fetchRawData(raw: endTime) as? String
        } else {
            return nil
        }
    }

    var redPacketID: String? {
        if let packetId = redPacketExtraData["packetId"] {
            return fetchRawData(raw: packetId) as? String
        } else {
            return nil
        }
    }

    var redPacketAddress: String? {
        if let packetAddress = redPacketExtraData["packetAddress"] {
            return fetchRawData(raw: packetAddress) as? String
        } else {
            return nil
        }
    }
}

// MARK: Sticker
public extension Dictionary where Key == String, Value == RawJSON {
    var stickerUrl: String? {
        if let stickerUrl = self["stickerUrl"] {
            return fetchRawData(raw: stickerUrl) as? String
        } else {
            return nil
        }
    }

    var giphyUrl: String? {
        if let stickerUrl = self["giphyUrl"] {
            return fetchRawData(raw: stickerUrl) as? String
        } else {
            return nil
        }
    }
}
