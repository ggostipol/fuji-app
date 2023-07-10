//
//  VPNManager.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 04.08.2020.
//

import NetworkExtension
import KeychainSwift

final class VPNManager: NSObject {
    private let KEYCHAIN_VPN_PASSWORD = "vpn_password"
    
    private let manager = NEVPNManager.shared()
    
    static let shared = VPNManager()
    
    private let keychain = KeychainSwift()
    
    var status: NEVPNStatus {
        return manager.connection.status
    }
    
    private override init() {
        super.init()
        loadProfile(callback: nil)
        manager.localizedDescription = Bundle.main.infoDictionary![kCFBundleNameKey as String] as? String
        manager.isEnabled = true
    }
    
    func requestPermission(connection: Connection, permissionHandler: @escaping (Bool) -> Void) {
        connect(connection, false, onError: nil, permissionHandler: permissionHandler)
    }
    
    func connect(_ connection: Connection, _ isOnDemand: Bool, onError: ((String) -> Void)?, permissionHandler: ((Bool) -> Void)? = nil) {
        keychain.set(connection.password, forKey: KEYCHAIN_VPN_PASSWORD)
        let passwordDataRef = keychain.getData(KEYCHAIN_VPN_PASSWORD, asReference: true)
        guard let passwordRef = passwordDataRef else {
            onError?("Unable to save password to keychain")
            return
        }
        connectToServer(connection.ip, connection.login, connection.remoteId, connection.localId, connection.serverCertificateCommonName, passwordRef, isOnDemand, onError, permissionHandler
        )
    }
    
    func disconnect() {
        manager.onDemandRules = []
        manager.isOnDemandEnabled = false
        manager.connection.stopVPNTunnel()
        manager.saveToPreferences()
    }
    
    func disconnectOnDemand(completion: @escaping (Bool) -> Void) {
        loadProfile() { result, errorDescription in
            if let error = errorDescription {
                print(error)
            }
            completion(result)
        }
    }
    
    private func loadProfile(callback: ((Bool, String?) -> Void)?) {
        manager.protocolConfiguration = nil
        manager.loadFromPreferences { [unowned self] error in
            if let error = error {
                callback?(false, error.localizedDescription)
            } else {
                callback?(self.manager.protocolConfiguration != nil, nil)
            }
        }
    }
    
    private func saveProfile(callback: ((Bool, String?) -> Void)?) {
        manager.saveToPreferences { error in
            if let error = error {
                callback?(false, error.localizedDescription)
            } else {
                callback?(true, nil)
            }
        }
    }
    
    private func connectToServer(_ ip: String, _ login: String, _ remoteId: String, _ localId: String, _ serverCertificateCommonName: String, _ passwordRef: Data, _ isOnDemand: Bool, _ onError: ((String) -> Void)?, _ permissionHandler: ((Bool) -> Void)?) {
        let vpnProtocol = NEVPNProtocolIKEv2()
        vpnProtocol.serverAddress = ip
        vpnProtocol.authenticationMethod = NEVPNIKEAuthenticationMethod.certificate
        vpnProtocol.deadPeerDetectionRate = NEVPNIKEv2DeadPeerDetectionRate.medium
        vpnProtocol.username = login
        vpnProtocol.passwordReference = passwordRef
        vpnProtocol.certificateType = .RSA
        vpnProtocol.serverCertificateCommonName = serverCertificateCommonName
        vpnProtocol.remoteIdentifier = remoteId
        vpnProtocol.localIdentifier = localId
        vpnProtocol.disconnectOnSleep = false
        vpnProtocol.disableMOBIKE = false
        vpnProtocol.disableRedirect = false
        vpnProtocol.enableRevocationCheck = false
        vpnProtocol.enablePFS = false
        vpnProtocol.useExtendedAuthentication = true
        vpnProtocol.useConfigurationAttributeInternalIPSubnet = false
        vpnProtocol.ikeSecurityAssociationParameters.encryptionAlgorithm = .algorithmAES256
        vpnProtocol.ikeSecurityAssociationParameters.integrityAlgorithm = .SHA256
        vpnProtocol.ikeSecurityAssociationParameters.diffieHellmanGroup = .group14
        vpnProtocol.childSecurityAssociationParameters.encryptionAlgorithm = .algorithmAES256
        vpnProtocol.childSecurityAssociationParameters.integrityAlgorithm = .SHA256
        vpnProtocol.childSecurityAssociationParameters.diffieHellmanGroup = .group14
        manager.protocolConfiguration = vpnProtocol
        if isOnDemand {
            manager.isOnDemandEnabled = true
            var rules = [NEOnDemandRule]()
            let allInterfacesRule = NEOnDemandRuleConnect()
            allInterfacesRule.interfaceTypeMatch = .any
            rules.append(allInterfacesRule)
            manager.onDemandRules = rules
        }
        manager.isEnabled = true
        saveProfile { [weak self] success, errorDescription in
            if let handler = permissionHandler {
                handler(success)
                return
            }
            guard success else {
                onError?(errorDescription!)
                return
            }
            self?.loadProfile() { [weak self] success, errorDescription in
                guard let self = self else { return }
                guard success else {
                    onError?(errorDescription!)
                    return
                }
                
                let (result, error) = self.startVPNTunnel()
                guard result else {
                    onError?(error!)
                    return
                }
            }
        }
    }
    
    private func startVPNTunnel() -> (result: Bool, error: String?) {
        var errorDescription: String?
        do {
            try self.manager.connection.startVPNTunnel()
            return (true, nil)
        } catch NEVPNError.configurationInvalid {
            errorDescription = "Failed to start tunnel (configuration invalid)"
        } catch NEVPNError.configurationDisabled {
            errorDescription = "Failed to start tunnel (configuration disabled)"
        } catch {
            errorDescription = "Failed to start tunnel (other error)"
        }
        return (false, errorDescription)
    }
}
