//
//  PurchaseVC.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 13.07.2020.
//

import UIKit
import Lottie
import ApphudSDK
import StoreKit
import SMIconLabel
import SafariServices
import BLTNBoard
import KeychainSwift
import YandexMobileMetrica
import ApphudSDK

class PurchaseVC: UIViewController {
    weak var delegate: PurchaseDelegate?
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var emptyView: UIView!
    
    @IBOutlet weak var progress: UIActivityIndicatorView!
    
    @IBOutlet weak var firstPriceStack: UIStackView!
    @IBOutlet weak var secondPriceStack: UIStackView!
    @IBOutlet weak var thirdPriceStack: UIStackView!

    @IBOutlet weak var firstPriceImage: UIImageView!
    @IBOutlet weak var secondPriceImage: UIImageView!
    @IBOutlet weak var thirdPriceImage: UIImageView!

    @IBOutlet weak var termsOfUseButton: UIButton!
    @IBOutlet weak var privacyPolicyButton: UIButton!
    @IBOutlet weak var purchaseButton: UIButton!
    @IBOutlet weak var restorePurchaseButton: UIButton!
    
    @IBOutlet weak var mainLabel: SMIconLabel!
        
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var secondNameLabel: UILabel!
    @IBOutlet weak var thirdNameLabel: UILabel!
    
    @IBOutlet weak var firstPriceLabel: UILabel!
    @IBOutlet weak var secondPriceLabel: UILabel!
    @IBOutlet weak var thirdPriceLabel: UILabel!
    
    @IBOutlet weak var firstDurationLabel: UILabel!
    @IBOutlet weak var secondDurationLabel: UILabel!
    @IBOutlet weak var thirdDurationLabel: UILabel!
    
    @IBOutlet weak var emptyPriceTitleLabel: UILabel!
    @IBOutlet weak var emptyPriceTextLabel: UILabel!
    
    @IBOutlet weak var emptyPriceImage: UIImageView!
    
    @IBOutlet weak var save: UILabel!
    @IBOutlet weak var firstSale: UILabel!
    @IBOutlet weak var secondSale: UILabel!
    
    @IBAction func termsOfUseButtonAction(_ sender: UIButton) {
        openUrl(URL(string: termsOfUseUrl)!)
    }

    @IBAction func privacyPolicyButtonAction(_ sender: UIButton) {
        openUrl(URL(string: privacyUrl)!)
    }

    @IBAction func purchaseButtonAction(_ sender: UIButton) {
        var tag = 0
        if activeScreen == 2 {
            tag = activeTagPrice
        } else {
            tag = activeTagPrice - 3
        }
        guard let products = products else {
            return
        }
        if !products.isEmpty {
            showEmptyView()
            startProgress()
            Apphud.purchase((products.first(where: {$0.productIdentifier == ids[tag]})?.productIdentifier)!, callback: { result in
                if (result.error == nil) {
                    reportEvent("purchase", ["screen": self.activeScreen, "sandbox": Apphud.isSandbox()])
                    self.subscribe()
                } else {
                    self.stopProgress()
                    self.showMainView()
                }
            })
        }
    }
    
    @IBAction func closeButtonAction(_ sender: UIButton) {
        closeScreen(false)
    }

    @IBAction func restorePurchaseButtonAction(_ sender: UIButton) {
        showEmptyView()
        startProgress()
        Apphud.restorePurchases { subscriptions, purchases, error in
            if Apphud.hasActiveSubscription() {
                self.subscribe()
            } else {
                self.stopProgress()
                self.showMainView()
            }
       }
    }
    
    private var activeTagPrice = 3
    private var activeTagCheck = 6
    private var activeScreen = 1
    private var products: [SKProduct]?
    
    private let monthlyFirst = "com.fuji.vpn.monthly.first.subscription"
    private let weeklyFirst = "com.fuji.vpn.weekly.first.subscription"
    private let yearlyFirst = "com.fuji.vpn.yearly.first.subscription"
    
    private let monthlySecond = "com.fuji.vpn.monthly.second.subscription"
    private let weeklySecond = "com.fuji.vpn.weekly.second.subscription"
    
    private let weeklyThird = "com.fuji.vpn.weekly.third.subscription"
    
    private var ids = [String]()
    
    private var timer: Timer?
    
    lazy var bulletinManager: BLTNItemManager = {
        let introPage = BulletinDataSource.noInternetConnectionPage()
        return BLTNItemManager(rootItem: introPage)
    }()
    
    private let keychain = KeychainSwift()
    private var isShowing = false
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addObserver()
        prepareUI()
        start()
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(serverErrorPageDissmiss), name: .ServerErrorPageDissmiss, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(noInternetConnectionPageDissmiss), name: .NoInternetConnectionPageDissmiss, object: nil)
    }
    
    @objc func serverErrorPageDissmiss() {
        start()
    }

    @objc func noInternetConnectionPageDissmiss() {
        start()
    }
    
    private func closeScreen(_ success: Bool) {
        delegate?.success(success)
        dismiss(animated: true)
    }
    
    private func subscribe() {
        DispatchQueue.global(qos: .utility).async {
            AppInteractor.shared.subscribe() { state in
                DispatchQueue.main.async {
                    self.stopProgress()
                }
                switch state {
                case .success:
                    DispatchQueue.main.async {
                        self.closeScreen(true)
                    }
                case .failure:
                    DispatchQueue.main.async {
                        self.reloadManager(.error)
                        self.showBulletin()
                    }
                case .serverError(_):
                    DispatchQueue.main.async {
                        self.reloadManager(.error)
                        self.showBulletin()
                    }
                case .occurredError:
                    DispatchQueue.main.async {
                        self.reloadManager(.error)
                        self.showBulletin()
                    }
                }
            }
        }
    }
    
    private func start() {
        isShowing = keychain.getBool("is_showing") ?? false
        startProgress()
        if Apphud.products != nil {
            products = Apphud.products
        }
        stopProgress()
        activeScreen = AppRepository.shared.getScreen()
        reportEvent("screen_show", ["screen": activeScreen, "sandbox": Apphud.isSandbox()])
        ids.append(monthlyFirst)
        ids.append(weeklyFirst)
        ids.append(yearlyFirst)
        ids.append(weeklySecond)
        ids.append(weeklyThird)
        ids.append(monthlySecond)
        guard let products = products else {
            reloadManager(.error)
            showBulletin()
            return
        }
        if !products.isEmpty {
            if activeScreen == 2 && !isShowing {
                keychain.set(true, forKey: "is_showing")
                firstNameLabel.text = "1 Month"
                firstPriceLabel.text = products.first(where: {$0.productIdentifier == weeklySecond})?.localizedPriceFrom(price: products.first(where: {$0.productIdentifier == weeklySecond})?.price ?? 0)
                firstDurationLabel.text = "peer week"
                
                secondNameLabel.text = "1 Week"
                secondPriceLabel.text = "FREE"
                secondDurationLabel.text = "peer week"
                
                thirdNameLabel.text = "6 Months"
                thirdPriceLabel.text = products.first(where: {$0.productIdentifier == monthlySecond})?.localizedPriceFrom(price: products.first(where: {$0.productIdentifier == monthlySecond})?.price ?? 0)
                thirdDurationLabel.text = "peer month"
                
                firstSale.text = "\(String(format: "%.0f", (products.first(where: {$0.productIdentifier == weeklySecond})?.price.doubleValue ?? 0) * 4)) \(products.first(where: {$0.productIdentifier == weeklySecond})?.priceLocale.currencySymbol ?? "-")"
                var attributeString: NSMutableAttributedString = NSMutableAttributedString(string: firstSale.text!)
                    attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSRange(location: 0, length: attributeString.length))
                firstSale.attributedText = attributeString
                
                secondSale.text = "\(String(format: "%.0f", (products.first(where: {$0.productIdentifier == monthlySecond})?.price.doubleValue ?? 0) * 12)) \(products.first(where: {$0.productIdentifier == monthlySecond})?.priceLocale.currencySymbol ?? "-")"
                attributeString = NSMutableAttributedString(string: secondSale.text!)
                    attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSRange(location: 0, length: attributeString.length))
                secondSale.attributedText = attributeString
                
                save.text = "SAVE \(String(format: "%.0f", 100 - (((products.first(where: {$0.productIdentifier == monthlySecond})?.price.doubleValue ?? 0) * 100) / ((products.first(where: {$0.productIdentifier == weeklySecond})?.price.doubleValue ?? 0) * 26))))%"
            } else {
                firstNameLabel.text = products.first(where: {$0.productIdentifier == monthlyFirst})?.localizedTitle
                firstPriceLabel.text = products.first(where: {$0.productIdentifier == monthlyFirst})?.localizedPriceFrom(price: products.first(where: {$0.productIdentifier == monthlyFirst})?.price ?? 0)
                firstDurationLabel.text = "peer month"
                
                secondNameLabel.text = products.first(where: {$0.productIdentifier == weeklyFirst})?.localizedTitle
                secondPriceLabel.text = products.first(where: {$0.productIdentifier == weeklyFirst})?.localizedPriceFrom(price: products.first(where: {$0.productIdentifier == weeklyFirst})?.price ?? 0)
                secondDurationLabel.text = "peer week"
                
                thirdNameLabel.text = products.first(where: {$0.productIdentifier == yearlyFirst})?.localizedTitle
                thirdPriceLabel.text = products.first(where: {$0.productIdentifier == yearlyFirst})?.localizedPriceFrom(price: products.first(where: {$0.productIdentifier == yearlyFirst})?.price ?? 0)
                thirdDurationLabel.text = "per year"
                
                firstSale.text = "\(String(format: "%.0f", (products.first(where: {$0.productIdentifier == weeklyFirst})?.price.doubleValue ?? 0) * 4)) \(products.first(where: {$0.productIdentifier == weeklyFirst})?.priceLocale.currencySymbol ?? "-")"
                var attributeString: NSMutableAttributedString = NSMutableAttributedString(string: firstSale.text!)
                    attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSRange(location: 0, length: attributeString.length))
                firstSale.attributedText = attributeString
                
                secondSale.text = "\(String(format: "%.0f", (products.first(where: {$0.productIdentifier == monthlyFirst})?.price.doubleValue ?? 0) * 12)) \(products.first(where: {$0.productIdentifier == monthlyFirst})?.priceLocale.currencySymbol ?? "-")"
                attributeString = NSMutableAttributedString(string: secondSale.text!)
                    attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSRange(location: 0, length: attributeString.length))
                secondSale.attributedText = attributeString
                save.text = "SAVE \(String(format: "%.0f", 100 - (((products.first(where: {$0.productIdentifier == yearlyFirst})?.price.doubleValue ?? 0) * 100) / ((products.first(where: {$0.productIdentifier == weeklyFirst})?.price.doubleValue ?? 0) * 52))))%"
            }
            showMainView()
        } else {
            reloadManager(.error)
            showBulletin()
        }
    }
    
    private func showBulletin() {
        bulletinManager.backgroundViewStyle = .dimmed
        bulletinManager.statusBarAppearance = .hidden
        bulletinManager.showBulletin(above: self)
    }
    
    private func reloadManager(_ page: Pages) {
        switch page {
        case .connection:
            bulletinManager = BLTNItemManager(rootItem: BulletinDataSource.noInternetConnectionPage())
        case .error:
            bulletinManager = BLTNItemManager(rootItem: BulletinDataSource.serverErrorPage())
        case .accept:
            break
        }
    }
    
    private func startProgress() {
        var start = 1
        timer =  Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            switch start {
            case 1:
                self.emptyPriceImage.image = UIImage(named: "empty_price_two")
                self.emptyPriceTitleLabel.text = "empty_price_title_two".localized
                start = 2
                break
            case 2:
                self.emptyPriceImage.image = UIImage(named: "empty_price_three")
                self.emptyPriceTitleLabel.text = "empty_price_title_three".localized
                start = 3
                break
            case 3:
                self.emptyPriceImage.image = UIImage(named: "empty_price")
                self.emptyPriceTitleLabel.text = "empty_price_title".localized
                start = 1
                break
            default:
                break
            }
        }
        progress.startAnimating()
    }

    private func stopProgress() {
        timer?.invalidate()
        emptyPriceImage.image = UIImage(named: "empty_price")
        emptyPriceTitleLabel.text = "empty_price_title".localized
        progress.stopAnimating()
    }
    
    private func showMainView() {
        mainView.isHidden = false
        emptyView.isHidden = true
    }
    
    private func showEmptyView() {
        mainView.isHidden = true
        emptyView.isHidden = false
    }
    
    private func prepareUI() {
        emptyPriceImage.image = UIImage(named: "empty_price")
        emptyPriceTextLabel.text = "empty_price_text".localized
        emptyPriceTitleLabel.text = "empty_price_title".localized
        showEmptyView()
        progress.hidesWhenStopped = true
        mainLabel.icon = UIImage(named: "shield")
        mainLabel.iconPadding = 5
        mainLabel.iconPosition = (.left, .center)
        purchaseButton.backgroundColor = firstButtonColor
        purchaseButton.layer.shadowColor = firstButtonColor.cgColor
        purchaseButton.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        purchaseButton.layer.shadowOpacity = 1.0
        purchaseButton.layer.shadowRadius = 4.0
        purchaseButton.layer.masksToBounds = false
        restorePurchaseButton.setTitleColor(secondButtonColor, for: .normal)
        termsOfUseButton.setTitleColor(secondButtonColor, for: .normal)
        privacyPolicyButton.setTitleColor(secondButtonColor, for: .normal)
        firstPriceImage.layer.shadowColor = shadow.cgColor
        firstPriceImage.layer.shadowOffset = CGSize(width: 5.0, height: 5.0)
        firstPriceImage.layer.shadowOpacity = 0.8
        firstPriceImage.layer.shadowRadius = 4.0
        firstPriceImage.layer.masksToBounds = false
        secondPriceImage.layer.shadowColor = shadow.cgColor
        secondPriceImage.layer.shadowOffset = CGSize(width: 5.0, height: 5.0)
        secondPriceImage.layer.shadowOpacity = 0.8
        secondPriceImage.layer.shadowRadius = 4.0
        secondPriceImage.layer.masksToBounds = false
        thirdPriceImage.layer.shadowColor = shadow.cgColor
        thirdPriceImage.layer.shadowOffset = CGSize(width: 5.0, height: 5.0)
        thirdPriceImage.layer.shadowOpacity = 0.8
        thirdPriceImage.layer.shadowRadius = 4.0
        thirdPriceImage.layer.masksToBounds = false
        firstPriceStack.tag = 0
        secondPriceStack.tag = 1
        thirdPriceStack.tag = 2
        firstPriceImage.tag = 3
        secondPriceImage.tag = 4
        thirdPriceImage.tag = 5
        firstPriceStack.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handlePriceTap(_:))))
        secondPriceStack.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handlePriceTap(_:))))
        thirdPriceStack.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handlePriceTap(_:))))
    }
    
    func openUrl(_ url: URL) {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        let vc = SFSafariViewController(url: url, configuration: config)
        present(vc, animated: true)
    }
    
    @objc func handlePriceTap(_ sender: UITapGestureRecognizer) {
        let tagPrice = sender.view!.tag + 3
        let tagCheck = tagPrice + 3
        if tagPrice != activeTagPrice {
            if let view = view.viewWithTag(tagPrice) as? UIImageView {
                view.image = UIImage(named: "price_2")
            }
            if let view = view.viewWithTag(activeTagPrice) as? UIImageView {
                view.image = UIImage(named: "price_1")
            }
            if let view = view.viewWithTag(tagCheck) as? UIImageView {
                view.alpha = 1.0
            }
            if let view = view.viewWithTag(activeTagCheck) as? UIImageView {
                view.alpha = 0.0
            }
            activeTagPrice = tagPrice
            activeTagCheck = tagCheck
        }
    }
}
