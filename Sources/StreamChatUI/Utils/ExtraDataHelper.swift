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
}
