//
//  AppInteractor.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 08.08.2020.
//

import Foundation

enum DataState {
    case success
    case failure
    case serverError(String)
    case occurredError
}

class AppInteractor {
    private let appRepository: AppRepository
    private let api: Api

    static let shared = AppInteractor(AppRepository.shared, Api.shared)

    private init(_ appRepository: AppRepository, _ api: Api) {
        self.appRepository = appRepository
        self.api = api
    }
    
    func getCountries(_ completionHandler: @escaping (DataState) -> Void) {
        api.getCountries() { state in
            switch state {
            case .success(let data):
                guard let data = data else {
                    debugPrint("Error: data is nil in getCountries")
                    completionHandler(.occurredError)
                    return
                }
                do {
                    let response = try JSONDecoder().decode(Response<Countries>.self, from: data)
                    if response.result {
                        guard let countries = response.data else {
                            debugPrint("Error: countries is nil in getCountries")
                            completionHandler(.occurredError)
                            return
                        }
                        self.appRepository.setCountries(countries)
                        completionHandler(.success)
                    }
                } catch let error {
                    debugPrint("Error: failure decode Response in getCountries: \(error.localizedDescription)")
                    completionHandler(.occurredError)
                }
            case .failure:
                completionHandler(.failure)
            }
        }
    }
    
    func getConfigs(_ completionHandler: @escaping (DataState) -> Void) {
        api.getConfigs() { state in
            switch state {
            case .success(let data):
                guard let data = data else {
                    debugPrint("Error: data is nil in getConfigs")
                    completionHandler(.occurredError)
                    return
                }
                do {
                    let response = try JSONDecoder().decode(Response<Configs>.self, from: data)
                    if response.result {
                        guard let configs = response.data else {
                            debugPrint("Error: configs is nil in getConfigs")
                            completionHandler(.occurredError)
                            return
                        }
                        self.appRepository.setConfigs(configs)
                        completionHandler(.success)
                    }
                } catch let error {
                    debugPrint("Error: failure decode Response in getConfigs: \(error.localizedDescription)")
                    completionHandler(.occurredError)
                }
            case .failure:
                completionHandler(.failure)
            }
        }
    }
    
    func getIPInfo(_ completionHandler: @escaping (DataState) -> Void) {
        api.getIPInfo() { state in
            switch state {
            case .success(let data):
                guard let data = data else {
                    debugPrint("Error: data is nil in getIPInfo")
                    completionHandler(.occurredError)
                    return
                }
                do {
                    let response = try JSONDecoder().decode(IPInfo.self, from: data)
                    self.appRepository.setIPInfo(response)
                    completionHandler(.success)
                } catch let error {
                    debugPrint("Error: failure decode Response in getIPInfo: \(error.localizedDescription)")
                    completionHandler(.occurredError)
                }
            case .failure:
                completionHandler(.failure)
            }
        }
    }
    
    func getScreen(_ completionHandler: @escaping (DataState) -> Void) {
        api.getScreen() { state in
            switch state {
            case .success(let data):
                guard let data = data else {
                    debugPrint("Error: data is nil in getScreen")
                    completionHandler(.occurredError)
                    return
                }
                do {
                    let response = try JSONDecoder().decode(Response<Int>.self, from: data)
                    if response.result {
                        guard let screen = response.data else {
                            debugPrint("Error: screen is nil in getScreen")
                            completionHandler(.occurredError)
                            return
                        }
                        self.appRepository.setScreen(screen)
                        completionHandler(.success)
                    }
                } catch let error {
                    debugPrint("Error: failure decode Response in getScreen: \(error.localizedDescription)")
                    completionHandler(.occurredError)
                }
            case .failure:
                completionHandler(.failure)
            }
        }
    }
    
    func subscribe(_ completionHandler: @escaping (DataState) -> Void) {
        api.subscribe() { state in
            switch state {
            case .success(let data):
                guard let data = data else {
                    debugPrint("Error: data is nil in subscribe")
                    completionHandler(.occurredError)
                    return
                }
                do {
                    let response = try JSONDecoder().decode(Response<JSONAny>.self, from: data)
                    if response.result {
                        completionHandler(.success)
                    }
                } catch let error {
                    debugPrint("Error: failure decode Response in subscribe: \(error.localizedDescription)")
                    completionHandler(.occurredError)
                }
            case .failure:
                completionHandler(.failure)
            }
        }
    }
}
