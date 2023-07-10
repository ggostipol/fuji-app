//
//  Utils.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 04.08.2020.
//

import UIKit
import Reachability
import SafariServices
import YandexMobileMetrica

func getReceipt() -> String {
    guard let url = Bundle.main.appStoreReceiptURL, let receipt = try? Data(contentsOf: url).base64EncodedString() else {
        return ""
    }
    return receipt
}

func countryName(from countryCode: String) -> String {
    if let name = (NSLocale(localeIdentifier: "en_US") as NSLocale).displayName(forKey: .countryCode, value: countryCode) {
        return name
    } else {
        return countryCode
    }
}

func reportEvent(_ event: String, _ param: [String: Any]) {
    YMMYandexMetrica.reportEvent(event, parameters: param, onFailure: { error in })
}

let debug: Bool = {
    var isDebug = false
    
    #if DEBUG
    isDebug = true
    #endif
    
    return isDebug
}()

func debug(_ items: Any...) {
    if debug {
        print("Debug:=====\(items)=====")
    }
}

enum Pages {
    case error
    case connection
    case accept
}

var currentLanguage: String!

let firstColor = UIColor(hexString: "#E8798A")
let secondColor = UIColor(hexString: "#FFDDE5")
let firstButtonColor = UIColor(hexString: "#F62459")
let secondButtonColor = UIColor(hexString: "#5388FF")
let shadow = UIColor(hexString: "#9ac8d5")

let privacyUrl = "https://fujivpn.com/privacy-policy"
let termsOfUseUrl = "https://fujivpn.com/terms-of-use"

enum Language: String {
    case english
    
    var name: String {
        switch self {
        case .english:
            return "English"
        }
    }
    
    var isoCode: String {
        switch self {
        case .english:
            return "en"
        }
    }
    
    init?(language: String) {
        switch language {
        case Language.english.name:
            self.init(rawValue: "english")
        default:
            return nil
        }
    }
    
    static func getLanguage(isoCode: String) -> String {
        switch isoCode {
        case Language.english.isoCode:
            return Language.english.name
        default:
            return ""
        }
    }
}

func isConnected() -> Bool {
    return try! Reachability().connection != .unavailable
}
