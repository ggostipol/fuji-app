//
//  Config.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 08.08.2020.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let configs = try? newJSONDecoder().decode(Config.self, from: jsonData)

import Foundation

// MARK: - Config
struct Config: Codable {
    let id: Int
    let countryId: Int
    let city: String
    let domain: String
    let ip: String
    let login: String
    let password: String

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case countryId = "country_id"
        case city = "city"
        case domain = "domain"
        case ip = "ip"
        case login = "login"
        case password = "password"
    }
}

typealias Configs = [Config]
