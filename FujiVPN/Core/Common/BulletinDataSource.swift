//
//  BulletinDataSource.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 16.08.2020.
//

import BLTNBoard

enum BulletinDataSource {

    static func serverErrorPage() -> BLTNPageItem {
        let page = BLTNPageItem(title: "oops".localized)
        page.descriptionText = "sometingWentWrong".localized
        page.actionButtonTitle = "tryAgain".localized
        page.appearance.buttonFontDescriptor = UIFontDescriptor(name: "ProximaNova-Regular", matrix: .identity)
        page.appearance.titleFontDescriptor = UIFontDescriptor(name: "ProximaNova-Bold", matrix: .identity)
        page.appearance.descriptionFontDescriptor = UIFontDescriptor(name: "ProximaNova-Regular", matrix: .identity)
        page.appearance.actionButtonColor = firstButtonColor
        page.requiresCloseButton = false
        page.isDismissable = false
        page.actionHandler = { item in
            item.manager?.dismissBulletin()
        }
        page.dismissalHandler = { item in
            NotificationCenter.default.post(name: .ServerErrorPageDissmiss, object: item)
        }
        return page
    }
    
    static func noInternetConnectionPage() -> BLTNPageItem {
        let page = BLTNPageItem(title: "oops".localized)
        page.descriptionText = "noInternetConnection".localized
        page.actionButtonTitle = "tryAgain".localized
        page.appearance.buttonFontDescriptor = UIFontDescriptor(name: "ProximaNova-Regular", matrix: .identity)
        page.appearance.titleFontDescriptor = UIFontDescriptor(name: "ProximaNova-Bold", matrix: .identity)
        page.appearance.descriptionFontDescriptor = UIFontDescriptor(name: "ProximaNova-Regular", matrix: .identity)
        page.appearance.actionButtonColor = firstButtonColor
        page.requiresCloseButton = false
        page.isDismissable = false
        page.actionHandler = { item in
            item.manager?.dismissBulletin()
        }
        page.dismissalHandler = { item in
            NotificationCenter.default.post(name: .NoInternetConnectionPageDissmiss, object: item)
        }
        return page
    }
}

extension Notification.Name {

    static let ServerErrorPageDissmiss = Notification.Name("ServerErrorPageDissmiss")
    static let NoInternetConnectionPageDissmiss = Notification.Name("NoInternetConnectionPageDissmiss")
}
