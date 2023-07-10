//
//  MainVCAppodealRewardedVideoDelegate.swift
//  
//
//  Created by  on 23.10.2022.
//

import Appodeal
import Amplitude_iOS

extension MainVC: AppodealRewardedVideoDelegate {
    // Method called when rewarded video loads
    //
    // - Parameter precache: If precache is YES it means that precached ad loaded
    func rewardedVideoDidLoadAdIsPrecache(_ precache: Bool) {
        debug("Appodeal!: rewardedVideoDidLoadAdIsPrecache")
    }
    
    // Method called if rewarded video mediation failed
    func rewardedVideoDidFailToLoadAd() {
        debug("Appodeal!: rewardedVideoDidFailToLoadAd")
    }

    // Method called if rewarded mediation was successful, but ready ad network can't show ad or
    // ad presentation was too frequent according to your placement settings
    //
    // - Parameter error: Error object that indicates error reason
    func rewardedVideoDidFailToPresentWithError(_ error: Error) {
        debug("Appodeal!: rewardedVideoDidFailToPresentWithError")
    }

    // Method called after rewarded video start displaying
    func rewardedVideoDidPresent() {
        debug("Appodeal!: rewardedVideoDidPresent")
    }
    
    // Method called before rewarded video leaves screen
    //
    // - Parameter wasFullyWatched: boolean flag indicated that user watch video fully
    func rewardedVideoWillDismissAndWasFullyWatched(_ wasFullyWatched: Bool) {
        debug("Appodeal!: rewardedVideoWillDismissAndWasFullyWatched")
    }

    //  Method called after fully watch of video
    //
    // - Warning: After call this method rewarded video can stay on screen and show postbanner
    // - Parameters:
    //   - rewardAmount: Amount of app curency tuned via Appodeal Dashboard
    //   - rewardName: Name of app currency tuned via Appodeal Dashboard
    func rewardedVideoDidFinish(_ rewardAmount: Float, name rewardName: String?) {
        getReward()
        debug("Appodeal!: rewardedVideoDidFinish")
    }

    // Method is called when rewarded video is clicked
    func rewardedVideoDidClick() {
        debug("Appodeal!: rewardedVideoDidClick")
        Amplitude.instance().logEvent("Video click")
    }

    // Method called when rewardedVideo did expire and can not be shown
    func rewardedVideoDidExpired() {
        debug("Appodeal!: rewardedVideoDidExpired")
    }
}
