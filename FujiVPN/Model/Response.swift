//
//  Response.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 09.08.2020.
//

import Foundation

// MARK: - Response
struct Response<T: Codable>: Codable {
    let result: Bool
    let data: T?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case result = "result"
        case data = "data"
        case error = "error"
    }
}
