//
//  Connection.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 08.08.2020.
//

import Foundation

// MARK: - Connection
public class Connection: Codable {
    public let ip: String
    public let login: String
    public let password: String
    public let remoteId: String
    public let localId: String
    public let serverCertificateCommonName: String
    public let countryName: String
    public let countryIso: String
    public var fastest: Bool
    public var city: String
    
    init(_ config: Config, _ country: Country) {
        self.ip = config.ip
        self.login = config.login
        self.password = config.password
        self.remoteId = config.domain
        self.localId = config.login
        self.serverCertificateCommonName = config.domain
        self.countryName = country.nameEn
        self.countryIso = country.iso
        self.fastest = false
        self.city = country.cities.first ?? ""
    }
    
    public func setFastest(_ fastest: Bool) {
        self.fastest = fastest
    }
}
