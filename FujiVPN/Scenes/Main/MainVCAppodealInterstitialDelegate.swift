//
//  MainVCAppodealInterstitialDelegate.swift
//  
//
//  Created by  on 07.11.2022.
//

import Appodeal
import Amplitude_iOS

extension MainVC: AppodealInterstitialDelegate {
    // Method called when precache (cheap and fast load) or usual interstitial view did load
    //
    // - Warning: If you want show only expensive ad, ignore this callback call with precache equal to YES
    // - Parameter precache: If precache is YES it's mean that precache loaded
    func interstitialDidLoadAdIsPrecache(_ precache: Bool) {
        debug("Appodeal!: interstitialDidLoadAdIsPrecache")
    }

    // Method called if interstitial mediation failed
    func interstitialDidFailToLoadAd() {
        debug("Appodeal!: interstitialDidFailToLoadAd")
    }
    
    // Method called if interstitial mediation was success, but ready ad network can't show ad or
    // ad presentation was to frequently according your placement settings
    func interstitialDidFailToPresent() {
        debug("Appodeal!: interstitialDidFailToPresent")
    }
    
    // Method called when interstitial will display on screen
    func interstitialWillPresent() {
        debug("Appodeal!: interstitialWillPresent")
    }

    // Method called after interstitial leave screeen
    func interstitialDidDismiss() {
        getReward()
        debug("Appodeal!: interstitialDidDismiss")
    }

    // Method called when user tap on interstitial
    func interstitialDidClick() {
        Amplitude.instance().logEvent("Interstitial click")
        debug("Appodeal!: interstitialDidClick")
    }
    
    // Method called when interstitial did expire and could not be shown
    func interstitialDidExpired() {
        debug("Appodeal!: interstitialDidExpired")
    }
}
