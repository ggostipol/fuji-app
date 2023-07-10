//
//  Api.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 13.07.2020.
//

import Alamofire
import ApphudSDK

enum ApiState {
    case success(Data?)
    case failure
}

class Api {
    private let appRepository: AppRepository
    private let endpoint = "https://fujivpn.com/api"
    private let token = "wjnIHN3R23OFBNUbnefowUF"
    
    static let shared = Api(AppRepository.shared)

    private init(_ appRepository: AppRepository) {
        self.appRepository = appRepository
    }
    
    func getIPInfo(_ completionHandler: @escaping (ApiState) -> Void) {
        request("https://geo.ipify.org/api/v1?apiKey=at_bplVwSCLfvvnSlkMLaxOiyo1WKsVg", .get, nil) { response in
            completionHandler(response)
        }
    }
    
    func getCountries(_ completionHandler: @escaping (ApiState) -> Void) {
        request("\(endpoint)/get-countries", .post, ["token": token]) { response in
            completionHandler(response)
        }
    }
    
    func getConfigs(_ completionHandler: @escaping (ApiState) -> Void) {
        request("\(endpoint)/get-servers", .post, ["uid": Apphud.userID(), "receipt": getReceipt(), "token": token]) { response in
            completionHandler(response)
        }
    }
    
    func getScreen(_ completionHandler: @escaping (ApiState) -> Void) {
        request("\(endpoint)/get-screen", .post, ["token": token]) { response in
            completionHandler(response)
        }
    }
    
    func subscribe(_ completionHandler: @escaping (ApiState) -> Void) {
        request("\(endpoint)/subscribe", .post, ["uid": Apphud.userID(), "receipt": getReceipt(), "token": token]) { response in
            completionHandler(response)
        }
    }
    
    // MARK: - Basic
    private func request(_ url: String,
                         _ method: HTTPMethod,
                         _ parameters: [String: Any]?,
                         _ completionHandler: @escaping (ApiState) -> Void) {
        debugPrint("/----------------START_REQUEST_PARAMS----------------/")
        debugPrint(url)
        debugPrint(method)
        debugPrint(parameters ?? "nil")
//        debugPrint(headers ?? "nil")
        debugPrint("/----------------END_REQUEST_PARAMS------------------/")
        AF.request(url,
                   method: method,
                   parameters: parameters,
                   encoding: URLEncoding.default,
                   headers: [.authorization(bearerToken: ""),
                    .accept("application/json")]).validate().response { response in
            switch response.result {
            case .success(let value):
                debugPrint("JSON String: \(String(data: value!, encoding: .utf8) ?? "")")
                completionHandler(.success(value))
            case .failure(let error):
                debugPrint(error)
                completionHandler(.failure)
            }
        }
    }
}
