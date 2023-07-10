//
//  VPN.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 04.08.2020.
//

import NetworkExtension

public enum VPNStatus {
    case connected
    case disconnected
    case connecting
    case reasserting
    case disconnecting
    case invalid
}

public enum ConnectStatus {
    case success
    case failure
}

public protocol VPNDelegate: AnyObject {
    func vpn(_ vpn: VPN, statusDidChange status: VPNStatus)
    func vpn(_ vpn: VPN, didRequestPermission status: ConnectStatus)
    func vpn(_ vpn: VPN, didConnectWithError error: String?)
    func vpnDidDisconnect(_ vpn: VPN)
}

public final class VPN {
    public static let shared = VPN(delegate: nil, connection: nil)
    public var connection: Connection?
    private var vpnStatus: NEVPNStatus!
    private let vpnManager: VPNManager
    public weak var delegate: VPNDelegate?
    
    init(delegate: VPNDelegate? = nil, connection: Connection? = nil) {
        self.vpnManager = VPNManager.shared
        self.delegate = delegate
        self.connection = connection
    }
    
    deinit {
        removeObservers()
    }
    
    public func addObservers(inQueue queue: OperationQueue = OperationQueue.main) {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: nil, queue: queue, using: { notification in
            let vpnConnection = notification.object as! NEVPNConnection
            self.vpnStatus = vpnConnection.status
            if self.vpnStatus == .connected {
                self.delegate?.vpn(self, statusDidChange: .connected)
            } else if self.vpnStatus == .disconnected {
                self.delegate?.vpn(self, statusDidChange: .disconnected)
            } else if self.vpnStatus == .connecting {
                self.delegate?.vpn(self, statusDidChange: .connecting)
            } else if self.vpnStatus == .reasserting {
                self.delegate?.vpn(self, statusDidChange: .reasserting)
            } else if self.vpnStatus == .disconnecting {
                self.delegate?.vpn(self, statusDidChange: .disconnecting)
            } else if self.vpnStatus == .invalid {
                self.delegate?.vpn(self, statusDidChange: .invalid)
            }
        })
    }
   
    public func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
    }
    
    public func requestPermission(inQueue queue: DispatchQueue = DispatchQueue.global(qos: .utility)) {
        guard let connection = connection else {
            delegate?.vpn(self, didRequestPermission: .failure)
            return
        }
        queue.async {
            self.vpnManager.requestPermission(connection: connection) { success in
                if success {
                    self.delegate?.vpn(self, didRequestPermission: .success)
                } else {
                    self.delegate?.vpn(self, didRequestPermission: .failure)
                }
            }
        }
    }
    
    public func toggleVpn() {
        if vpnStatus == .connected  {
            disconnect()
        } else if vpnStatus == .disconnected {
            connect()
        }
    }
    
    public func disconnectOnDemand() {
        vpnManager.disconnectOnDemand() { [weak self] _ in
            self?.disconnect()
        }
    }
    
    public func connect() {
        guard let connection = connection else {
            delegate?.vpn(self, didConnectWithError: "No connection available")
            return
        }
        vpnManager.connect(connection, true, onError: { error in
            self.delegate?.vpn(self, didConnectWithError: error)
        })
    }
    
    public func disconnect() {
        vpnManager.disconnect()
        delegate?.vpnDidDisconnect(self)
    }
    
    public func status() -> VPNStatus {
        switch vpnManager.status {
        case .connected:
            return .connected
        case .connecting:
            return .connecting
        case .disconnected:
            return .disconnected
        case .disconnecting:
            return .disconnecting
        case .invalid:
            return .invalid
        case .reasserting:
            return .reasserting
        @unknown default:
            fatalError()
        }
    }
}
