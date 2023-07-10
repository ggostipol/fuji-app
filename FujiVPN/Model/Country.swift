//
//  Country.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 13.07.2020.
//

import Foundation

struct Country: Codable, Equatable {
    let id: Int
    let iso: String
    let free: Bool
    let nameEn: String
    let cities: [String]

    enum CodingKeys: String, CodingKey {
        case id, iso, cities
        case free = "is_free"
        case nameEn = "name_en"
    }
}

typealias Countries = [Country]
