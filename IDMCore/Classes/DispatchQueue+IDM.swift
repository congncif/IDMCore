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
    public static let idmConcurrent = DispatchQueue(label: "com.if.idmcore.concurrent", attributes: .concurrent)
    public static let idmSerial = DispatchQueue(label: "com.if.idmcore.serial")
}
