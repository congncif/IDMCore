//
//  DispatchQueue+IDM.swift
//  IDMCore
//
//  Created by FOLY on 12/10/18.
//

import Foundation

extension DispatchQueue {
    public static let idmRunQueue: DispatchQueue = DispatchQueue(label: "com.if.idmcore", attributes: .concurrent)
}
