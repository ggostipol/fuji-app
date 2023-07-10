//
//  BottomSheetVC.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 13.07.2020.
//

import UIKit
import SMIconLabel
import SwiftMessages

class SelectCountryVC: UIViewController {
    @IBOutlet weak var selectedArrow: UIImageView!
    @IBOutlet weak var selectedCountry: SMIconLabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate: SelectCountryDelegate?
    
    public var connection: Connection?
    
    private var countries: [Country]!
    private var allCountries: [Country]!
    private var favCountries: [Country]!
    private var filtered = [Country]()
    private let reuseIdentifier = "SelectCountryCell"
    private var gesture: UIPanGestureRecognizer?
    
    private var isFiltering: Bool {
        return !(searchBar.text?.isEmpty ?? true)
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareData()
        prepareUI()
        connection = AppRepository.shared.connection
        setStatus()
    }
    
    private func prepareData() {
        countries = AppRepository.shared.getCountries()
        allCountries = AppRepository.shared.getCountries()
        favCountries = AppRepository.shared.getFavoriteCountries() ?? [Country]()
        for country in favCountries {
            if let index = allCountries.firstIndex(of: country) {
                allCountries.remove(at: index)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.6, animations: {
            self.moveView(state: .partial)
        })
    }
    
    private func prepareUI() {
        gesture = UIPanGestureRecognizer.init(target: self, action: #selector(panGesture))
        searchBar.placeholder = "search".localized
        searchBar.scopeButtonTitles = ["allcountries".localized, "favcountries".localized]
        searchBar.delegate = self
        tableView.register(UINib.init(nibName: reuseIdentifier, bundle: nil), forCellReuseIdentifier: reuseIdentifier)
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        if VPNManager.shared.status != .connected {
            addGesture()
        }
        roundViews()
    }
    
    public func addGesture() {
        view.addGestureRecognizer(gesture!)
    }
    
    public func removeGesture() {
        view.removeGestureRecognizer(gesture!)
    }
    
    private func setSelectedCountryName(_ name: String?) {
        selectedCountry.text = name
    }
    
    private func setSelectedCountryIcon(_ icon: String?) {
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
        selectedCountry.icon = image
        selectedCountry.iconPadding = 5
        selectedCountry.iconPosition = (.left, .center)
    }
    
    func setArrowIcon(_ icon: String) {
        selectedArrow.image = UIImage(named: icon)
    }
    
    public func setStatus() {
        setArrowIcon("arrow_up")
        if connection?.fastest ?? true {
            setSelectedCountryIcon("arrow")
            setSelectedCountryName("fastest".localized)
        } else {
            setSelectedCountryIcon(connection?.countryIso.uppercased())
            setSelectedCountryName(connection?.countryName)
        }
        selectedCountry.textColor = secondButtonColor
    }
    
    private func moveView(state: State) {
        if state == State.full {
            setArrowIcon("arrow_down")
        } else if state == State.partial {
            setArrowIcon("arrow_up")
        }
        let yPosition = state == .partial ? Constant.partialViewYPosition : Constant.fullViewYPosition
        self.view.endEditing(true)
        view.frame = CGRect(x: 0, y: yPosition, width: view.frame.width, height: view.frame.height)
    }

    private func moveView(panGestureRecognizer recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: view)
        let minY = view.frame.minY
        if (minY + translation.y >= Constant.fullViewYPosition) && (minY + translation.y <= Constant.partialViewYPosition) {
            view.frame = CGRect(x: 0, y: minY + translation.y, width: view.frame.width, height: view.frame.height)
            recognizer.setTranslation(CGPoint.zero, in: view)
        }
    }
    
    private func filterSearch() {
        filtered = countries.filter({$0.nameEn.lowercased().contains(searchBar.text!.lowercased())})
        tableView.reloadData()
    }
    
    @objc private func panGesture(_ recognizer: UIPanGestureRecognizer) {
        moveView(panGestureRecognizer: recognizer)
        if recognizer.state == .ended {
            UIView.animate(withDuration: 1, delay: 0.0, options: [.allowUserInteraction], animations: {
                let state: State = recognizer.velocity(in: self.view).y >= 0 ? .partial : .full
                self.moveView(state: state)
            }, completion: nil)
        }
    }
    
    private func roundViews() {
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
    }
    
    private func showMessage(_ message: String, _ theme: Theme) {
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(theme)
        view.configureDropShadow()
        view.configureContent(title: "", body: message.localized)
        view.button?.isHidden = true
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .top
        config.presentationContext = .window(windowLevel: UIWindow.Level.normal)
        SwiftMessages.show(config: config, view: view)
    }
}

extension SelectCountryVC {
    
    enum State {
        case partial
        case full
    }
    
    enum Constant {
        static let fullViewYPosition: CGFloat = 100
        static var partialViewYPosition: CGFloat { UIScreen.main.bounds.height - 120 }
    }
}

extension SelectCountryVC: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        if isFiltering {
            return 1
        }
        if favCountries.isEmpty {
            return 2
        } else {
            return 3
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return filtered.count
        }
        switch section {
        case 0:
            return 1
        case 1:
            if favCountries.isEmpty {
                return allCountries.count
            } else {
                return favCountries.count
            }
        case 2:
            return allCountries.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionName = ""
        switch section {
            case 1:
                if favCountries.isEmpty {
                    sectionName = "All countries:"
                } else {
                    sectionName = "Favorite location:"
                }
            case 2:
                sectionName = "All countries:"
            default:
                sectionName = ""
        }
        return sectionName
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! SelectCountryCell
        var country: Country?
        if isFiltering {
            country = filtered[indexPath.row]
        } else {
            if indexPath.section == 0 {
                if indexPath.row == 0 {
                    cell.countryFavorite.isHidden = true
                    cell.countryAvailability.isHidden = true
                    cell.countryPremium.isHidden = true
                    cell.countryName.text = "fastest".localized
                    var image = UIImage(named: "arrow_2")
                    image = image!.resized(to: CGSize(width: 19, height: 19))
                    cell.countryImage.image = image
                }
            } else if indexPath.section == 1 {
                cell.countryFavorite.isHidden = false
                cell.countryAvailability.isHidden = false
                cell.countryPremium.isHidden = false
                if favCountries.isEmpty {
                    country = allCountries[indexPath.row]
                } else {
                    country = favCountries[indexPath.row]
                }
            } else {
                cell.countryFavorite.isHidden = false
                cell.countryAvailability.isHidden = false
                cell.countryPremium.isHidden = false
                country = allCountries[indexPath.row]
            }
        }
        if country != nil {
            cell.delegate = self
            cell.setCountry(country!)
            cell.countryName.text = country!.nameEn
            if AppRepository.shared.isInFavorites(country!.id) {
                cell.countryFavorite.image = UIImage(named: "heart_fill")
            } else {
                cell.countryFavorite.image = UIImage(named: "heart")
            }
            if country!.free {
                cell.countryPremium.isHidden = true
            } else {
                cell.countryPremium.isHidden = false
            }
            if country!.free {
                cell.countryAvailability.image = UIImage(named: "signal")
            } else {
                cell.countryAvailability.image = UIImage(named: "signal_full")
            }
            var image = UIImage(named: country?.iso.uppercased() ?? "default")
            if image == nil {
                image = UIImage(named: "default")
            }
            image = image!.resized(to: CGSize(width: 19, height: 19))
            cell.countryImage.image = image
        }
        return cell
    }
}

extension SelectCountryVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var country: Country?
        var fastest = false
        if isFiltering {
            country = filtered[indexPath.row]
        } else {
            if indexPath.section == 0 {
                if indexPath.row == 0 {
                    fastest = true
                }
            } else if indexPath.section == 1 {
                if favCountries.isEmpty {
                    country = allCountries[indexPath.row]
                } else {
                    country = favCountries[indexPath.row]
                }
            } else {
                country = allCountries[indexPath.row]
            }
        }
        delegate?.setCountry(country, fastest)
        UIView.animate(withDuration: 0.6, animations: {
            self.moveView(state: .partial)
        })
    }
}

extension SelectCountryVC: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterSearch()
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterSearch()
    }
}

extension SelectCountryVC: SelectCountryCellDelegate {
    
    func favoriteAction(_ country: Country) {
        debug(country.id)
        if AppRepository.shared.isInFavorites(country.id) {
            debug("isInFavorites")
            if AppRepository.shared.deleteCountryFromFavorites(country) {
                showMessage("favoriteDeleted".localized, .success)
            }
        } else {
            debug("NONisInFavorites")
            if AppRepository.shared.addCountryToFavorites(country) {
                showMessage("favoriteAdded".localized, .success)
            }
        }
        prepareData()
        tableView.reloadData()
        //        filterSearch()
    }
}
