//
//  MainVC.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 13.07.2020.
//

import UIKit
import Lottie
import SMIconLabel
import BLTNBoard
import ApphudSDK
import StoreKit
import KeychainSwift
import Amplitude_iOS
import Appodeal

enum Rewarded {
    case connect
    case disconnect
}

protocol SelectCountryDelegate: AnyObject {
    func setCountry(_ country: Country?, _ fastest: Bool)
}

protocol PurchaseDelegate: AnyObject {
    func success(_ success: Bool)
}

class MainVC: UIViewController {
    @IBOutlet weak var startImage: UIImageView!
    @IBOutlet weak var stopImage: UIImageView!
    @IBOutlet weak var statusLabel: SMIconLabel!
    @IBOutlet weak var location: UIButton!
    @IBOutlet weak var ipLabel: SMIconLabel!
    @IBOutlet weak var stopAnimationView: LottieAnimationView!
    @IBOutlet weak var progressAnimationView: LottieAnimationView!
    @IBOutlet weak var logoTopConstraint: NSLayoutConstraint!
    
    @IBAction func locationAction(_ sender: UIButton) {
        UIView.animate(withDuration: 0.6, animations: {
            self.moveView(state: .full)
        })
    }
    
    private var ipInfo: IPInfo?
    private var config: Config?
    private var country: Country?
    private var connection: Connection?
    private var selectCountryVC: SelectCountryVC?
    private var isFromConnected = false
    private var isBottomAdded = false
    private var activeScreen = 1
    private var products: [SKProduct]?
    private var isRewarded = false
    private var rewarded: Rewarded!
    
    lazy var bulletinManager: BLTNItemManager = {
        let introPage = acceptRulesPage()
        return BLTNItemManager(rootItem: introPage)
    }()
    
    private let keychain = KeychainSwift()
    private var isShowing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.registerForRemoteNotifications()
        }
        Appodeal.setRewardedVideoDelegate(self)
        Appodeal.setInterstitialDelegate(self)
        prepareUI()
        start()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isBottomAdded {
            addBottomSheetView()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if Apphud.hasActiveSubscription() {
            Appodeal.setBannerDelegate(nil)
            hideBannerAds()
        } else {
            Appodeal.setBannerDelegate(self)
            showBannerAds()
        }
    }
    
    func constraintUp() {
        logoTopConstraint.constant = 70
    }
    
    func constraintDown() {
        logoTopConstraint.constant = 20
    }
    
    private func showBannerAds() {
        if Appodeal.isReadyForShow(with: .bannerTop) {
            constraintUp()
        }
        Appodeal.showAd(.bannerTop, rootViewController: self)
    }
    
    private func hideBannerAds() {
        Appodeal.hideBanner()
        constraintDown()
    }
    
    private func moveView(state: SelectCountryVC.State) {
        if state == SelectCountryVC.State.full {
            selectCountryVC?.setArrowIcon("arrow_down")
        } else if state == SelectCountryVC.State.partial {
            selectCountryVC?.setArrowIcon("arrow_up")
        }
        let yPosition = state == .partial ? SelectCountryVC.Constant.partialViewYPosition : SelectCountryVC.Constant.fullViewYPosition
        selectCountryVC?.view.frame = CGRect(x: 0, y: yPosition, width: view.frame.width, height: view.frame.height)
    }

    private func addBottomSheetView() {
        isBottomAdded = true
        selectCountryVC = SelectCountryVC()
        guard let selectCountryVC = selectCountryVC else {
            return
        }
        selectCountryVC.delegate = self
        self.addChild(selectCountryVC)
        self.view.addSubview(selectCountryVC.view)
        selectCountryVC.didMove(toParent: self)
        let height = view.frame.height
        let width  = view.frame.width
        selectCountryVC.view.frame = CGRect(x: 0, y: view.frame.maxY, width: width, height: height)
    }
    
    private func updateConnection() {
        if let country = country, let config = config {
            connection = Connection(config, country)
            connection?.fastest = false
        } else {
            if connection == nil {
                guard let country = AppRepository.shared.getCountries().randomElement() else {
                    return
                }
                guard let config = AppRepository.shared.getConfigs().filter({ $0.countryId == country.id }).first else {
                    return
                }
                connection = Connection(config, country)
                connection?.fastest = true
                AppRepository.shared.connection = connection
            }
        }
        VPN.shared.connection = connection
    }
    
    private func start() {
        isShowing = keychain.getBool("is_showing") ?? false
        activeScreen = AppRepository.shared.getScreen()
        let country = AppRepository.shared.getCountries().first(where: { $0.free })
        if country != nil {
            self.country = country
            config = AppRepository.shared.getConfigs().filter({ $0.countryId == country!.id }).first
        } else {
            let country = AppRepository.shared.getCountries().first
            self.country = country
            config = AppRepository.shared.getConfigs().filter({ $0.countryId == country!.id }).first
        }
        updateConnection()
        if Apphud.products != nil {
            products = Apphud.products
        }
        ipInfo = AppRepository.shared.getIPInfo()
        if !AppRepository.shared.isAllowedVPN {
            disconnected()
        }
        VPN.shared.addObservers()
        VPN.shared.delegate = self
        if (UserDefaults.standard.integer(forKey: "dl") != 0 && !isShowing) {
            DispatchQueue.main.async {
                self.openDeeplinkScreen()
            }
        }
    }
    
    private func prepareUI() {
        location.layer.cornerRadius = 12
        location.layer.borderWidth = 1
        location.layer.borderColor = UIColor(named: "border")?.cgColor
        
        stopAnimationView.animation = LottieAnimation.named("stop")
        stopAnimationView.contentMode = .scaleAspectFill
        stopAnimationView.loopMode = .loop
        
        progressAnimationView.animation = LottieAnimation.named("progress")
        progressAnimationView.contentMode = .scaleAspectFill
        progressAnimationView.loopMode = .loop
        
        ipLabel.icon = UIImage(named: "ip")
        ipLabel.iconPadding = 5
        ipLabel.iconPosition = (.left, .center)
        
        startImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleStartImageTap(_:))))
        stopImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleStopImageTap(_:))))
        stopAnimationView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleStopViewTap(_:))))
    }
    
    private func registerForRemoteNotifications() {
        (UIApplication.shared.delegate as! AppDelegate).registerForRemoteNotifications()
    }
    
    private func showInterstitialAd() {
        Appodeal.showAd(.interstitial, rootViewController: self)
    }
    
    private func showRewardedVideoAd() {
        Appodeal.showAd(.rewardedVideo, rootViewController: self)
    }
    
    @objc func handleStopImageTap(_ sender: UITapGestureRecognizer) {
        disconnectVPN()
    }
    
    @objc func handleStartImageTap(_ sender: UITapGestureRecognizer) {
        rewarded = .connect
        if activeScreen == 4 && !isShowing {
            if Apphud.hasActiveSubscription() {
                if AppRepository.shared.isAllowedVPN {
                    connectVPN()
                } else {
                    getPermissions()
                }
            } else {
                purchase()
            }
        } else if activeScreen == 3 && !isShowing {
            if AppRepository.shared.isAllowedVPN {
                if Apphud.hasActiveSubscription() {
                    connectVPN()
                } else {
                    purchase()
                }
            } else {
                getPermissions()
            }
        } else if activeScreen == 5 && !isShowing {
            if Apphud.hasActiveSubscription() {
                if AppRepository.shared.isAllowedVPN {
                    connectVPN()
                } else {
                    getPermissions()
                }
            } else {
                showAlert()
            }
        } else {
            if AppRepository.shared.isAllowedVPN {
                if Apphud.hasActiveSubscription() {
                    connectVPN()
                } else {
                    if country?.free ?? false {
                        if isRewarded {
                            isRewarded = false
                            connectVPN()
                        } else {
                            if Appodeal.isReadyForShow(with: .rewardedVideo) {
                                showRewardedVideoAd()
                            } else if (Appodeal.isReadyForShow(with: .interstitial)) {
                                showInterstitialAd()
                            } else {
                                getReward()
                            }
                        }
                    } else {
                        openPurchaseScreen()
                    }
                }
            } else {
                reloadManager(.accept)
                showBulletin()
            }
        }
    }
    
    func getReward() {
        isRewarded = true
        switch rewarded {
        case .connect:
            handleStartImageTap(UITapGestureRecognizer())
        case .disconnect:
            handleStopImageTap(UITapGestureRecognizer())
        case .none:
            break
        }
    }
    
    @objc func handleStopViewTap(_ sender: UITapGestureRecognizer) {
        rewarded = .disconnect
        if country?.free ?? false {
            if isRewarded {
                isRewarded = false
                disconnectVPN()
            } else {
                if Appodeal.isReadyForShow(with: .rewardedVideo) {
                    showRewardedVideoAd()
                } else if (Appodeal.isReadyForShow(with: .interstitial)) {
                    showInterstitialAd()
                } else {
                    getReward()
                }
            }
        } else {
            disconnectVPN()
        }
    }
    
    private func connectVPN() {
        Amplitude.instance().logEvent("vpnON")
        VPN.shared.connect()
    }
    
    private func disconnectVPN() {
        Amplitude.instance().logEvent("vpnOFF")
        VPN.shared.disconnect()
    }
    
    private func showBulletin() {
        bulletinManager.backgroundViewStyle = .dimmed
        bulletinManager.statusBarAppearance = .hidden
        bulletinManager.showBulletin(above: self)
    }
    
    private func reloadManager(_ page: Pages) {
        switch page {
        case .connection:
            break
        case .error:
            break
        case .accept:
            bulletinManager = BLTNItemManager(rootItem: acceptRulesPage())
        }
    }
    
    private func acceptRulesPage() -> BLTNPageItem {
        let page = BLTNPageItem(title: "rulesTitle".localized)
        let attributedString = NSMutableAttributedString(string: "rulesMessage".localized)
        let linkRangePolicy = attributedString.mutableString.range(of: "policy".localized)
        let linkRangeTerms = attributedString.mutableString.range(of: "terms".localized)
        attributedString.addAttribute(.link, value: URL(string: privacyUrl)!, range: linkRangePolicy)
        attributedString.addAttribute(.link, value: URL(string: termsOfUseUrl)!, range: linkRangeTerms)
        page.attributedDescriptionText = attributedString
        page.actionButtonTitle = "accept".localized
        page.alternativeButtonTitle = "cancel".localized
        page.appearance.buttonFontDescriptor = UIFontDescriptor(name: "ProximaNova-Regular", matrix: .identity)
        page.appearance.titleFontDescriptor = UIFontDescriptor(name: "ProximaNova-Bold", matrix: .identity)
        page.appearance.descriptionFontDescriptor = UIFontDescriptor(name: "ProximaNova-Regular", matrix: .identity)
        page.appearance.actionButtonColor = firstButtonColor
        page.requiresCloseButton = false
        page.isDismissable = false
        page.actionHandler = { item in
            item.manager?.dismissBulletin()
            self.getPermissions()
        }
        page.alternativeHandler = { item in
            item.manager?.dismissBulletin()
        }
        page.presentationHandler = { item in
            page.descriptionLabel?.isUserInteractionEnabled = true
        }
        return page
    }
    
    private func disconnecting() {
        if stopAnimationView.isAnimationPlaying {
            stopAnimationView.stop()
        }
        if progressAnimationView.isAnimationPlaying {
            progressAnimationView.stop()
        }
        startImage.isHidden = true
        stopImage.isHidden = true
        stopAnimationView.isHidden = true
        progressAnimationView.isHidden = false
        progressAnimationView.play()
        unSetStatusIcon()
        statusLabel.pushTransition(0.4, .fromLeft)
        statusLabel.text = "disconnecting".localized
    }
    
    private func connecting() {
        if stopAnimationView.isAnimationPlaying {
            stopAnimationView.stop()
        }
        if progressAnimationView.isAnimationPlaying {
            progressAnimationView.stop()
        }
        startImage.isHidden = true
        stopAnimationView.isHidden = true
//        progressAnimationView.isHidden = false
//        progressAnimationView.play()
        stopImage.isHidden = false
        unSetStatusIcon()
        statusLabel.pushTransition(0.4, .fromLeft)
        statusLabel.text = "connecting".localized
    }
    
    private func disconnected() {
        if stopAnimationView.isAnimationPlaying {
            stopAnimationView.stop()
        }
        if progressAnimationView.isAnimationPlaying {
            progressAnimationView.stop()
        }
        progressAnimationView.isHidden = true
        stopAnimationView.isHidden = true
        startImage.isHidden = false
        stopImage.isHidden = true
        setIp(ipInfo?.ip, .center)
        setLocationIcon(ipInfo?.location.country.uppercased())
        setLocationName("\(countryName(from: ipInfo?.location.country ?? "")) - \(ipInfo?.location.region ?? "")")
        setStatusIcon("alert")
        statusLabel.text = "disconnected".localized
        if activeScreen != 1 && !isShowing {
            statusLabel.text = "disconnected_black".localized
        }
    }
    
    private func connected() {
        if stopAnimationView.isAnimationPlaying {
            stopAnimationView.stop()
        }
        if progressAnimationView.isAnimationPlaying {
            progressAnimationView.stop()
        }
        startImage.isHidden = true
        stopImage.isHidden = true
        progressAnimationView.isHidden = true
        stopAnimationView.isHidden = false
        stopAnimationView.play()
        setIp(connection?.ip, .center)
        ipLabel.pushTransition(0.4, .fromLeft)
        setLocationIcon(connection?.countryIso.uppercased())
        setLocationName("\(connection?.countryName ?? "") - \(connection?.city ?? "")")
        location.pushTransition(0.4, .fromLeft)
        setStatusIcon("shield")
        statusLabel.pushTransition(0.4, .fromLeft)
        statusLabel.text = "connected".localized
        if activeScreen != 1 && !isShowing {
            statusLabel.text = "connected_black".localized
        }
    }
    
    private func showAlert() {
        let alert = UIAlertController(title: "\"FujiVPN private proxy\" Would Like to Add VPN Configurations", message: "All network activity on this iPhone may be filtered or monitored when using VPN.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Allow", style: UIAlertAction.Style.default, handler: { _ in
            self.purchase()
        }))
        alert.addAction(UIAlertAction(title: "Don't Allow", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func setStatusIcon(_ icon: String) {
        statusLabel.icon = UIImage(named: icon)
        statusLabel.iconPadding = 5
        statusLabel.iconPosition = (.left, .center)
    }
    
    private func unSetStatusIcon() {
        statusLabel.icon = nil
    }
    
    private func setIp(_ ip: String?, _ alignment: NSTextAlignment) {
        ipLabel.text = ip
        ipLabel.textAlignment = alignment
    }
    
    private func setLocationIcon(_ icon: String?) {
        var image: UIImage!
        if let icon = icon {
            image = UIImage(named: icon)
        } else {
            image = UIImage(named: "default")
        }
        if image == nil {
            image = UIImage(named: "default")
        }
        image = image.resized(to: CGSize(width: 19, height: 19))
        location.setImage(image, for: .normal)
    }
    
    private func setLocationName(_ name: String?) {
        location.setTitle(name, for: .normal)
    }
    
    private func getPermissions() {
        DispatchQueue.global(qos: .utility).async {
            VPN.shared.requestPermission()
        }
    }
    
    private func purchase() {
        reportEvent("screen_show", ["screen": activeScreen, "sandbox": Apphud.isSandbox()])
        keychain.set(true, forKey: "is_showing")
        guard let products = products else {
            reloadManager(.error)
            showBulletin()
            return
        }
        if !products.isEmpty {
            Apphud.purchase((products.first(where: {$0.productIdentifier == "com.fuji.vpn.weekly.third.subscription"})?.productIdentifier)!, callback: { result in
                if (result.error == nil) {
                    reportEvent("purchase", ["screen": self.activeScreen, "sandbox": Apphud.isSandbox()])
                    self.subscribe()
                }
            })
        } else {
            reloadManager(.error)
            showBulletin()
        }
    }
    
    private func subscribe() {
        DispatchQueue.global(qos: .utility).async {
            AppInteractor.shared.subscribe() { state in
                switch state {
                case .success:
                    DispatchQueue.main.async {
                        if AppRepository.shared.isAllowedVPN {
                            self.connectVPN()
                        } else {
                            self.getPermissions()
                        }
                    }
                    break
                case .failure:
                    break
                case .serverError(_):
                    break
                case .occurredError:
                    break
                }
            }
        }
    }
    
    private func openPurchaseScreen() {
        let vc = UIStoryboard(name: "Purchase", bundle: nil).instantiateViewController(withIdentifier: "Purchase") as! PurchaseVC
        vc.modalPresentationStyle = .fullScreen
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    private func openDeeplinkScreen() {
        let vc = UIStoryboard(name: "Deeplink", bundle: nil).instantiateViewController(withIdentifier: "Deeplink") as! DeeplinkVC
        vc.modalPresentationStyle = .fullScreen
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
}

extension MainVC: VPNDelegate {
    
    func vpnDidDisconnect(_ vpn: VPN) {
        
    }
    
    func vpn(_ vpn: VPN, statusDidChange status: VPNStatus) {
        switch status {
        case .connected:
            location.isUserInteractionEnabled = false
            selectCountryVC?.removeGesture()
            AppRepository.shared.connection = connection
            connected()
        case .connecting:
            connecting()
        case .disconnecting:
            isFromConnected = true
            disconnecting()
        case .disconnected:
            location.isUserInteractionEnabled = true
            selectCountryVC?.addGesture()
            if ipInfo?.ip == connection?.ip {
                DispatchQueue.global(qos: .utility).async {
                    AppInteractor.shared.getIPInfo() { state in
                        switch state {
                        case .success:
                            DispatchQueue.main.async {
                                self.ipInfo = AppRepository.shared.getIPInfo()
                                self.disconnected()
                            }
                        case .failure:
                            break
                        case .serverError(_):
                            break
                        case .occurredError:
                            break
                        }
                    }
                }
            } else {
                if isFromConnected {
                    isFromConnected = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                        self.disconnected()
                    }
                } else {
                    disconnected()
                }
            }
        default:
            break
        }
    }
    
    func vpn(_ vpn: VPN, didConnectWithError error: String?) {
        debugPrint(error ?? "")
    }
    
    func vpn(_ vpn: VPN, didRequestPermission status: ConnectStatus) {
        guard status == .success else {
            return
        }
        AppRepository.shared.isAllowedVPN = true
        if activeScreen == 3 && !isShowing || activeScreen == 4 && !isShowing || activeScreen == 5 && !isShowing {
            if Apphud.hasActiveSubscription() {
                connectVPN()
            } else {
                purchase()
            }
        } else {
            if Apphud.hasActiveSubscription() {
                connectVPN()
            } else {
                openPurchaseScreen()
            }
        }
    }
}

extension MainVC: PurchaseDelegate {
    
    func success(_ success: Bool) {
        if success {
            connectVPN()
        }
    }
}

extension MainVC: SelectCountryDelegate {
    
    func setCountry(_ country: Country?, _ fastest: Bool) {
        if (fastest) {
            self.country = nil
            config = nil
            connection = nil
            updateConnection()
        } else {
            guard let country = country else {
                return
            }
            self.country = country
            config = AppRepository.shared.getConfigs().filter({ $0.countryId == country.id }).first
            updateConnection()
        }
        selectCountryVC?.connection = connection
        selectCountryVC?.setStatus()
    }
}
