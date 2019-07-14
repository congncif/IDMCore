//
//  DispatchQueue+IDM.swift
//  IDMCore
//
//  Created by FOLY on 12/10/18.
//

import Foundation

extension DispatchQueue {
    public static let running = DispatchQueue(label: "com.if.idmcore.running", attributes: .concurrent)
    public static let momentum = DispatchQueue(label: "com.if.idmcore.momentum", attributes: .concurrent)
    public static let concurrent = DispatchQueue(label: "com.if.idmcore.concurrent", attributes: .concurrent)
    public static let serial = DispatchQueue(label: "com.if.idmcore.serial")
}

public enum IntegrationCallQueue {
    case main
    case serial

    public var dispatchQueue: DispatchQueue {
        switch self {
        case .main:
            return DispatchQueue.main
        default:
            return DispatchQueue.serial
        }
    }
}
