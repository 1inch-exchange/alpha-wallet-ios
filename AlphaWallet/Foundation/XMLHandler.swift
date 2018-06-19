//
//  XMLHandler.swift
//  AlphaWallet
//
//  Created by James Sangalli on 11/4/18.
//

import Foundation
import SwiftyXMLParser
import BigInt
import TrustKeystore

//  Dictionary class for non fungible token
//  TODO handle flexible attribute names e.g. asset, contract
//  Handle generics for multiple asset defintions

public class XMLHandler {

    private let xml = try! XML.parse(AssetDefinitionXML().assetDefinitionString)

    func getFifaInfoForTicket(tokenId tokenBytes32: BigUInt, index: UInt16) -> Ticket {
        //check if leading or trailing zeros
        let tokenId = tokenBytes32
        guard tokenId != 0 else { return .empty }
        let lang = getLang()
        let tokenHex = MarketQueueHandler.bytesToHexa(tokenBytes32.serialize().bytes)
        let fields = extractFields()

        //TODO should check for nil and handle rather than default to any value in this class. Or maybe the asset definition XML is missing. Otherwise, it should be returning a reasonable default already
        let locality: String = fields["locality"]?.extract(from: tokenHex) ?? "N/A"
        let venue: String = fields["venue"]?.extract(from: tokenHex) ?? "N/A"
        let time: GeneralisedTime = fields["time"]?.extract(from: tokenHex) ?? .init()
        let countryA: String = fields["countryA"]?.extract(from: tokenHex) ?? ""
        let countryB: String = fields["countryB"]?.extract(from: tokenHex) ?? ""
        let match: Int = fields["match"]?.extract(from: tokenHex) ?? 0
        let category: String = fields["category"]?.extract(from: tokenHex) ?? "N/A"
        let numero: Int = fields["numero"]?.extract(from: tokenHex) ?? 0

        return Ticket(
                id: MarketQueueHandler.bytesToHexa(tokenId.serialize().array),
                index: index,
                city: locality,
                name: getName(lang: lang),
                venue: venue,
                match: match,
                date: time,
                seatId: numero,
                category: category,
                countryA: countryA,
                countryB: countryB
        )
    }

    private func extractFields() -> [String: AssetAttribute] {
        let lang = getLang()
        var fields = [String: AssetAttribute]()
        for e in xml["token"]["attribute-types"]["attribute-type"] {
            if let id = e.attributes["id"], case let .singleElement(element) = e {
                fields[id] = AssetAttribute(attribute: element, lang: lang)
            }
        }
        return fields
    }

    func getAddressFromXML(server: RPCServer) -> Address {
        if server == .ropsten {
            if let address = xml["token"]["contract"][0]["address"][1].text {
                return Address(string: address)!
            }
        } else {
            if let address = xml["token"]["contract"][0]["address"][0].text {
                return Address(string: address)!
            }
        }
        return Address(string: Constants.ticketContractAddressRopsten)!
    }

    func getName(lang: String) -> String {
        //TODO do we always want the first one?
        if let name = xml["token"]["contract"][0]["name"].getElementWithLangAttribute(equals: lang)?.text {
            return name
        }
        return "N/A"
    }
    
    func getLang() -> String {
        let lang = Locale.preferredLanguages[0]
        if lang.hasPrefix("en") {
            return "en"
        } else if lang.hasPrefix("zh") {
            return "zh"
        } else if lang.hasPrefix("es") {
            return "es"
        } else if lang.hasPrefix("ru") {
            return "ru"
        }
        return "en"
    }
}

