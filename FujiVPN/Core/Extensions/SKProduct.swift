//
//  SKProduct.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 12.08.2020.
//

import Foundation
import UIKit
import StoreKit
import ApphudSDK

extension SKProduct {

    func localizedPriceFrom(price: NSDecimalNumber) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = priceLocale
        numberFormatter.currencyCode = priceLocale.currencyCode
        numberFormatter.currencySymbol = priceLocale.currencySymbol
        let priceString = numberFormatter.string(from: price)
        return priceString ?? ""
    }
}
