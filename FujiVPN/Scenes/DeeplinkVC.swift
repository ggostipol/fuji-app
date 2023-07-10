//
//  DeeplinkVC.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 10.02.2021.
//

import Foundation
import UIKit
import ApphudSDK
import StoreKit
import KeychainSwift

class DeeplinkVC: UIViewController {
    weak var delegate: PurchaseDelegate?
    
    @IBAction func submitTdl(_ sender: UIButton) {
        purchase()
    }
    
    @IBAction func submitSdl(_ sender: UIButton) {
        purchase()
    }
    
    @IBAction func submitFdl(_ sender: UIButton) {
        purchase()
    }
    
    @IBOutlet weak var firstPartTitleFdl: UILabel!
    @IBOutlet weak var secondPartTitleFdl: UILabel!
    @IBOutlet weak var firstBooTextFdl: UILabel!
    @IBOutlet weak var secondBooTextFdl: UILabel!
    @IBOutlet weak var thirdBooTextFdl: UILabel!
    
    @IBOutlet weak var firstPartTitleSdl: UILabel!
    @IBOutlet weak var secondPartTitleSdl: UILabel!
    @IBOutlet weak var firstBooTextSdl: UILabel!
    @IBOutlet weak var secondBooTextSdl: UILabel!
    
    @IBOutlet weak var firstPartTitleTdl: UILabel!
    @IBOutlet weak var secondPartTitleTdl: UILabel!
    @IBOutlet weak var firstBooTextTdl: UILabel!
    @IBOutlet weak var secondBooTextTdl: UILabel!
    
    @IBOutlet weak var submitFdl: UIButton!
    @IBOutlet weak var submitSdl: UIButton!
    @IBOutlet weak var submitTdl: UIButton!
    
    @IBOutlet weak var dlT: UIView!
    @IBOutlet weak var dlS: UIView!
    @IBOutlet weak var dlF: UIView!
    
    private var products: [SKProduct]?
    private var dl: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if Apphud.products != nil {
            products = Apphud.products
        }
        dl = UserDefaults.standard.integer(forKey: "dl")
        let lg = UserDefaults.standard.string(forKey: "lg")
        KeychainSwift().set(true, forKey: "is_showing")
        UserDefaults.standard.set(0, forKey: "dl")
        if lg == "ar" || lg == "he-IL" {
            UIView.appearance().semanticContentAttribute = .forceRightToLeft
            firstPartTitleFdl.textAlignment = .right
            secondPartTitleFdl.textAlignment = .right
            firstBooTextFdl.textAlignment = .right
            secondBooTextFdl.textAlignment = .right
            thirdBooTextFdl.textAlignment = .right
            
            firstPartTitleSdl.textAlignment = .right
            secondPartTitleSdl.textAlignment = .right
            firstBooTextSdl.textAlignment = .right
            secondBooTextSdl.textAlignment = .right
            
            firstPartTitleTdl.textAlignment = .right
            secondPartTitleTdl.textAlignment = .right
            firstBooTextTdl.textAlignment = .right
            secondBooTextTdl.textAlignment = .right
        }
        switch dl {
        case 1:
            firstPartTitleFdl.text = "first_part_title_fdl".localized(lg: lg ?? "en")
            secondPartTitleFdl.text = "second_part_title_fdl".localized(lg: lg ?? "en")
            firstBooTextFdl.text = "first_boo_text_fdl".localized(lg: lg ?? "en")
            secondBooTextFdl.text = "second_boo_text_fdl".localized(lg: lg ?? "en")
            thirdBooTextFdl.text = "third_boo_text_fdl".localized(lg: lg ?? "en")
            submitFdl.setTitle("submit_fdl".localized(lg: lg ?? "en"), for: .normal)
            dlF.isHidden = false
            break
        case 2:
            firstPartTitleSdl.text = "first_part_title_sdl".localized(lg: lg ?? "en")
            secondPartTitleSdl.text = "second_part_title_sdl".localized(lg: lg ?? "en")
            firstBooTextSdl.text = "first_boo_text_sdl".localized(lg: lg ?? "en")
            secondBooTextSdl.text = "second_boo_text_sdl".localized(lg: lg ?? "en")
            submitSdl.setTitle("submit_sdl".localized(lg: lg ?? "en"), for: .normal)
            dlS.isHidden = false
            break
        case 3:
            firstPartTitleTdl.text = "first_part_title_tdl".localized(lg: lg ?? "en")
            secondPartTitleTdl.text = "second_part_title_tdl".localized(lg: lg ?? "en")
            firstBooTextTdl.text = "first_boo_text_tdl".localized(lg: lg ?? "en")
            secondBooTextTdl.text = "second_boo_text_tdl".localized(lg: lg ?? "en")
            submitTdl.setTitle("submit_tdl".localized(lg: lg ?? "en"), for: .normal)
            dlT.isHidden = false
            break
        default:
            break
        }
    }
    
    private func purchase() {
        guard let products = products else {
            return
        }
        if !products.isEmpty {
            Apphud.purchase((products.first(where: {$0.productIdentifier == "com.fuji.vpn.weekly.first.subscription"})?.productIdentifier)!, callback: { result in
                if (result.error == nil) {
                    reportEvent("purchase", ["screen": self.dl!, "sandbox": Apphud.isSandbox()])
                    self.subscribe()
                }
            })
        }
    }
    
    private func subscribe() {
        DispatchQueue.global(qos: .utility).async {
            AppInteractor.shared.subscribe() { state in
                DispatchQueue.main.async {
                    
                }
                switch state {
                case .success:
                    DispatchQueue.main.async {
                        self.closeScreen(true)
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
    
    private func closeScreen(_ success: Bool) {
        delegate?.success(success)
        dismiss(animated: true)
    }
}
