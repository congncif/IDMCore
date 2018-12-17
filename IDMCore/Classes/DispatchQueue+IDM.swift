//
//  DispatchQueue+IDM.swift
//  IDMCore
//
//  Created by FOLY on 12/10/18.
//

import Foundation

extension DispatchQueue {
    public static let idmRunQueue: DispatchQueue = DispatchQueue(label: "com.if.idmcore.run", attributes: .concurrent)
    public static let idmPrepareQueue: DispatchQueue = DispatchQueue(label: "com.if.idmcore.prepare", attributes: .concurrent)
    public static let idmQueue: DispatchQueue = DispatchQueue(label: "com.if.idmcore", attributes: .concurrent)
}
