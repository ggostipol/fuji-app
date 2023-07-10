//
//  IPInfo.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 09.08.2020.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let iPInfo = try? newJSONDecoder().decode(IPInfo.self, from: jsonData)

import Foundation

// MARK: - IPInfo
struct IPInfo: Codable {
    let ip: String
    let location: Location
    let domains: [String]?
    let ipInfoAs: As?
    let isp: String

    enum CodingKeys: String, CodingKey {
        case ip = "ip"
        case location = "location"
        case domains = "domains"
        case ipInfoAs = "as"
        case isp = "isp"
    }
}

// MARK: - As
struct As: Codable {
    let asn: Int
    let name: String
    let route: String
    let domain: String
    let type: String

    enum CodingKeys: String, CodingKey {
        case asn = "asn"
        case name = "name"
        case route = "route"
        case domain = "domain"
        case type = "type"
    }
}

// MARK: - Location
struct Location: Codable {
    let country: String
    let region: String
    let city: String
    let lat: Double
    let lng: Double
    let postalCode: String
    let timezone: String
    let geonameId: Int?

    enum CodingKeys: String, CodingKey {
        case country = "country"
        case region = "region"
        case city = "city"
        case lat = "lat"
        case lng = "lng"
        case postalCode = "postalCode"
        case timezone = "timezone"
        case geonameId = "geonameId"
    }
}
