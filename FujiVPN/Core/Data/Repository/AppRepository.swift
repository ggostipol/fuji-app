//
//  AppRepository.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 04.08.2020.
//

import Foundation
import KeychainSwift

class AppRepository {
    private var countries = [Country]()
    private var configs = [Config]()
    private var ipInfo: IPInfo?
    private var screen: Int!
    
    private let keychain = KeychainSwift()
    
    static let shared = AppRepository()
    
    private init() {
        if !isFavoriteDeletedOnce() {
            if let _ = getFavoriteCountries() {
                UserDefaults.standard.set(nil, forKey: "favorite")
            }
        }
    }
    
    func isFavoriteDeletedOnce() -> Bool {
        if UserDefaults.standard.bool(forKey: "isFavoriteDeletedOnce") {
            return true
        } else {
            UserDefaults.standard.set(true, forKey: "isFavoriteDeletedOnce")
            return false
        }
    }
    
    // MARK: - Country
    func setCountries(_ countries: [Country]) {
        self.countries = countries
    }
    
    func getCountries() -> [Country] {
        return countries
    }
    
    // MARK: - IPInfo
    func setIPInfo(_ ipInfo: IPInfo) {
        self.ipInfo = ipInfo
    }
    
    func getIPInfo() -> IPInfo? {
        return ipInfo
    }
    
    // MARK: - Screen
    func setScreen(_ screen: Int) {
        self.screen = screen
    }
    
    func getScreen() -> Int {
        return screen
    }
    
    // MARK: - Favorite Countries
    func addCountryToFavorites(_ county: Country) -> Bool {
        guard var countries = getFavoriteCountries() else {
            return false
        }
        countries.append(county)
        return setFavoriteCountries(countries)
    }
    
    func deleteCountryFromFavorites(_ country: Country) -> Bool {
        guard var countries = getFavoriteCountries() else {
            return false
        }
        countries.removeAll(where: { $0.id ==  country.id})
        return setFavoriteCountries(countries)
    }
    
    private func setFavoriteCountries(_ countries: [Country]) -> Bool {
        do {
            UserDefaults.standard.set(try JSONEncoder().encode(countries), forKey: "favorite")
            return true
        } catch _ {
            return false
        }
    }
    
    func isInFavorites(_ id: Int) -> Bool {
        for country in getFavoriteCountries() ?? [Country]() {
            if id == country.id {
                return true
            }
        }
        return false
    }
    
    func getFavoriteCountries() -> [Country]? {
        guard let data = UserDefaults.standard.value(forKey: "favorite") as? Data else {
            return [Country]()
        }
        do {
            return try JSONDecoder().decode(Countries.self, from: data)
        } catch _ {
            return [Country]()
        }
    }
    
    // MARK: - Config
    func setConfigs(_ configs: [Config]) {
        self.configs = configs
    }
    
    func getConfigs() -> [Config] {
        return configs
    }
    
    // MARK: - Screen
    func isScreenWasShow() -> Bool {
        return keychain.getBool("screen") ?? false
    }
    
    func setIsScreenWasShow() {
        keychain.set(true, forKey: "screen")
    }
    
    // MARK: - Connection
    var connection: Connection? {
        get {
            guard let data = UserDefaults.standard.value(forKey: "connection") as? Data else {
                return nil
            }
            return try? JSONDecoder().decode(Connection.self, from: data)
        }
        set(data) {
            UserDefaults.standard.set(try? JSONEncoder().encode(data), forKey: "connection")
        }
    }
    
    // MARK: - isAllowedVPN
    var isAllowedVPN: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "isAllowedVPN") 
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: "isAllowedVPN")
        }
    }
}
