//
//  SplashVC.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 13.07.2020.
//

import UIKit
import GTProgressBar
import BLTNBoard
import SafariServices
import ApphudSDK

class SplashVC: UIViewController {
    @IBOutlet weak var progressBar: GTProgressBar!
    
    private var timer: Timer?
    private var successGetCountries = false
    private var successGetConfigs = false
    private var successGetIPInfo = false
    private var successGetScreen = false
    private var successGetProducts = true
    
    lazy var bulletinManager: BLTNItemManager = {
        let introPage = BulletinDataSource.noInternetConnectionPage()
        return BLTNItemManager(rootItem: introPage)
    }()
    
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
    
    private func start() {
        if isConnected() {
            startProgress()
            let group = DispatchGroup()
//            group.enter()
//            getProducts() { success in
//                self.successGetProducts = success
//                debugPrint("getProducts success \(success)")
//                group.leave()
//            }
            group.enter()
            getCountries() { success in
                self.successGetCountries = success
                debugPrint("getCountries success \(success)")
                group.leave()
            }
            group.enter()
            getScreen() { success in
                self.successGetScreen = success
                debugPrint("getScreen success \(success)")
                group.leave()
            }
            group.enter()
            getConfigs() { success in
                self.successGetConfigs = success
                debugPrint("getConfigs success \(success)")
                group.leave()
            }
            group.enter()
            getIPInfo() { success in
                self.successGetIPInfo = success
                debugPrint("getIPInfo success \(success)")
                group.leave()
            }
            group.notify(queue: .main) {
                debugPrint("all jobs is success")
                self.stopProgress()
                if self.successGetCountries && self.successGetConfigs && self.successGetScreen && self.successGetIPInfo && self.successGetProducts {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.openMainScreen()
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.progressBar.isHidden = true
                        self.reloadManager(.error)
                        self.showBulletin()
                    }
                }
            }
        } else {
            reloadManager(.connection)
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
    
    private func getCountries(_ completionHandler: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            AppInteractor.shared.getCountries() { state in
                switch state {
                case .success:
                    completionHandler(true)
                case .failure:
                    completionHandler(false)
                case .serverError(_):
                    completionHandler(false)
                case .occurredError:
                    completionHandler(false)
                }
            }
        }
    }
    
    private func getProducts(_ completionHandler: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            if Apphud.products != nil {
                completionHandler(true)
            } else {
                Apphud.fetchProducts { products, error  in
                    if error == nil {
                        completionHandler(true)
                    } else {
                        completionHandler(false)
                    }
                }
            }
        }
    }
    
    private func getScreen(_ completionHandler: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            AppInteractor.shared.getScreen() { state in
                switch state {
                case .success:
                    completionHandler(true)
                case .failure:
                    completionHandler(false)
                case .serverError(_):
                    completionHandler(false)
                case .occurredError:
                    completionHandler(false)
                }
            }
        }
    }
    
    private func getConfigs(_ completionHandler: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            AppInteractor.shared.getConfigs() { state in
                switch state {
                case .success:
                    completionHandler(true)
                case .failure:
                    completionHandler(false)
                case .serverError(_):
                    completionHandler(false)
                case .occurredError:
                    completionHandler(false)
                }
            }
        }
    }
    
    private func getIPInfo(_ completionHandler: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            AppInteractor.shared.getIPInfo() { state in
                switch state {
                case .success:
                    completionHandler(true)
                case .failure:
                    completionHandler(false)
                case .serverError(_):
                    completionHandler(false)
                case .occurredError:
                    completionHandler(false)
                }
            }
        }
    }
    
    private func stopProgress() {
        timer?.invalidate()
        progressBar.animateTo(progress: 1.0)
    }
    
    private func startProgress() {
        progressBar.progress = 0.0
        progressBar.isHidden = false
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            let progress = self.progressBar.progress
            if progress == 1.0 {
                timer.invalidate()
            } else {
                self.progressBar.animateTo(progress: progress + 0.01)
            }
        }
    }
    
    private func prepareUI() {
        progressBar.barFillColor = firstColor
        progressBar.barBackgroundColor = secondColor
    }
    
    private func openMainScreen() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Main") as! MainVC
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
}
