//
//  String.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 04.08.2020.
//

import UIKit

extension String {
    
    func localized(lg: String) -> String {
        if let path = Bundle.main.path(forResource: lg, ofType: "lproj") {
            return Bundle(path: path)!.localizedString(forKey: self, value: nil, table: "LocalizedStrings")
        } else if let path = Bundle.main.path(forResource: "en", ofType: "lproj") {
            return Bundle(path: path)!.localizedString(forKey: self, value: nil, table: "LocalizedStrings")
        } else {
            return "Error getting string recources"
        }
    }
    
    var localized: String {
        if let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj") {
            return Bundle(path: path)!.localizedString(forKey: self, value: nil, table: "LocalizedStrings")
        } else if let path = Bundle.main.path(forResource: "en", ofType: "lproj") {
            return Bundle(path: path)!.localizedString(forKey: self, value: nil, table: "LocalizedStrings")
        } else {
            return "Error getting string recources"
        }
    }
}
