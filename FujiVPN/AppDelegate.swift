//
//  AppDelegate.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 13.07.2020.
//

import UIKit
import Firebase
import FirebaseMessaging
import FirebaseAnalytics
import FirebaseCrashlytics
import ApphudSDK
import StoreKit
import UserNotificationsUI
import KeychainSwift
import YandexMobileMetrica
import AdSupport
import AppTrackingTransparency
import BranchSDK
import Amplitude_iOS
import Appodeal
import AppsFlyerLib

private struct AppodealConstants {
    static let key: String = "10e7dcac7068748c84c8102fedd2cac4feaec4b5c1bbc385"
    static let adTypes: AppodealAdType = [.interstitial, .rewardedVideo, .banner]
    static let logLevel: APDLogLevel = .off
    static let testMode: Bool = debug
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var ConversionData: [AnyHashable: Any]? = nil

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        currentLanguage = Language.english.isoCode
        
//        KeychainSwift().set(false, forKey: "is_showing")
        
        Apphud.setDelegate(self)
        Apphud.start(apiKey: "app_hUjeuLmuW6EZB9t4BeHNgt8ADCDoBr")
        
        AppsFlyerLib.shared().appsFlyerDevKey = "p3Uu6gxVxFiwwypuaQhSEh"
        AppsFlyerLib.shared().appleAppID = "1527248400"
        AppsFlyerLib.shared().customerUserID = Apphud.userID()
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
        
        AppsFlyerLib.shared().delegate = self
        
        STKConsentManager.shared().disableAppTrackingTransparencyRequest()
        Appodeal.updateUserConsentGDPR(.nonPersonalized)
        Appodeal.updateUserConsentCCPA(.optOut)
        Appodeal.setUserId(Apphud.userID())
        Appodeal.setAutocache(true, types: AppodealConstants.adTypes)
        Appodeal.initialize(withApiKey: AppodealConstants.key, types: AppodealConstants.adTypes)
        
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        Crashlytics.crashlytics().setUserID(Apphud.userID())
        FirebaseAnalytics.Analytics.setUserID(Apphud.userID())
        
        let configuration = YMMYandexMetricaConfiguration.init(apiKey: "87352b62-dd21-42ee-8261-a8ff420dda29")
        configuration?.crashReporting = false
        YMMYandexMetrica.activate(with: configuration!)
        YMMYandexMetrica.setUserProfileID(Apphud.userID())
        
        Amplitude.instance().trackingSessionEvents = true
        Amplitude.instance().setUserId(Apphud.userID())
        Amplitude.instance().initializeApiKey("d7da0a77086727a82d20bb874f20d8e8")
        
        Branch.getInstance().setIdentity(Apphud.userID())
        Branch.getInstance().initSession(launchOptions: launchOptions) { (params, error) in
            guard let dl = params?["dl"], let lg = params?["lg"] else {
                UserDefaults.standard.set(0, forKey: "dl")
                UserDefaults.standard.set("en", forKey: "lg")
                return
            }
            UserDefaults.standard.set(dl, forKey: "dl")
            UserDefaults.standard.set(lg, forKey: "lg")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        return true
    }
    
    func registerForRemoteNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (_, _) in }
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    @objc func applicationDidBecomeActive() {
        AppsFlyerLib.shared().start()
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                guard status == .authorized else {
                    return
                }
                let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                debugPrint("IDFA: \(idfa)")
                Apphud.setAdvertisingIdentifier(idfa)
                Amplitude.instance().useAdvertisingIdForDeviceId()
            }
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        Branch.getInstance().application(app, open: url, options: options)
        AppsFlyerLib.shared().handleOpen(url, options: options)
        return true
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        Branch.getInstance().continue(userActivity)
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
        return true
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        AppsFlyerLib.shared().handlePushNotification(userInfo)
        Branch.getInstance().handlePushNotification(userInfo)
    }
}

extension AppDelegate: MessagingDelegate {

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        debugPrint("Firebase registration token: \(fcmToken ?? "nil")")
//        NotificationCenter.default.post(name: Constants.fcmTokenUpdateNotification, object: nil, userInfo: [Constants.fcmToken: fcmToken])
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
}

extension AppDelegate: ApphudDelegate {
    
    func apphudDidFetchStoreKitProducts(_ products: [SKProduct]) {}

    func apphudDidFetchStoreKitProducts(_ products: [SKProduct], _ error: Error?) {}

    func apphudDidObservePurchase(result: ApphudPurchaseResult) -> Bool {
        debugPrint("Did observe purchase made without Apphud SDK: \(result)")
        return true
    }
    
    func apphudDidChangeUserID(_ userID: String) {
        Amplitude.instance().setUserId(userID)
        Branch.getInstance().setIdentity(userID)
        YMMYandexMetrica.setUserProfileID(userID)
        Crashlytics.crashlytics().setUserID(userID)
        FirebaseAnalytics.Analytics.setUserID(userID)
        Appodeal.setUserId(userID)
        AppsFlyerLib.shared().customerUserID = userID
    }
}

extension AppDelegate: AppsFlyerLibDelegate {
     
    // Handle Organic/Non-organic installation
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        ConversionData = data
        print("onConversionDataSuccess data:")
        for (key, value) in data {
            print(key, ":", value)
        }
        if let conversionData = data as NSDictionary? as! [String:Any]? {
        
            if let status = conversionData["af_status"] as? String {
                if (status == "Non-organic") {
                    if let sourceID = conversionData["media_source"],
                        let campaign = conversionData["campaign"] {
                        NSLog("[AFSDK] This is a Non-Organic install. Media source: \(sourceID)  Campaign: \(campaign)")
                    }
                } else {
                    NSLog("[AFSDK] This is an organic install.")
                }
                
                if let is_first_launch = conversionData["is_first_launch"] as? Bool,
                    is_first_launch {
                    NSLog("[AFSDK] First Launch")
                    if !conversionData.keys.contains("deep_link_value") && conversionData.keys.contains("fruit_name"){
                        switch conversionData["fruit_name"] {
                            case let fruitNameStr as String:
                            NSLog("This is a deferred deep link opened using conversion data")
//                            walkToSceneWithParams(fruitName: fruitNameStr, deepLinkData: conversionData)
                            default:
                                NSLog("Could not extract deep_link_value or fruit_name from deep link object using conversion data")
                                return
                        }
                    }
                } else {
                    NSLog("[AFSDK] Not First Launch")
                }
            }
        }
    }
    
    func onConversionDataFail(_ error: Error) {
        NSLog("[AFSDK] \(error)")
    }
}
