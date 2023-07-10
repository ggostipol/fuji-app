//
//  MainVCAppodealBannerDelegate.swift
//  
//
//  Created by  on 23.10.2022.
//

import Appodeal
import Amplitude_iOS

extension MainVC: AppodealBannerDelegate {
    // banner was loaded (precache flag shows if the loaded ad is precache)
    func bannerDidLoadAdIsPrecache(_ precache: Bool) {
        constraintUp()
        debug("Appodeal!: bannerDidLoadAdIsPrecache")
    }
    // banner was shown
    func bannerDidShow() {
        debug("Appodeal!: bannerDidShow")
    }
    // banner failed to load
    func bannerDidFailToLoadAd() {
        debug("Appodeal!: bannerDidFailToLoadAd")
    }
    // banner was clicked
    func bannerDidClick() {
        Amplitude.instance().logEvent("Banner click")
        debug("Appodeal!: bannerDidClick")
    }
    // banner did expire and could not be shown
    func bannerDidExpired() {
        debug("Appodeal!: bannerDidExpired")
    }
}
