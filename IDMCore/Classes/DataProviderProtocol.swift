//
//  DataProtocol.swift
//  Pods
//
//  Created by NGUYEN CHI CONG on 8/15/16.
//
//

import Foundation

public typealias CancelHandler = () -> Void

public protocol DataProviderProtocol {
    associatedtype ParameterType
    associatedtype DataType

    /// Implement this method for requesting/fetching/getting data from Internet/Database/Storage files, ...
    ///
    /// - Parameters:
    ///   - parameters: conditions of request
    ///   - completion: call completion to forward data to next processing (Integration)
    /// - Returns: a closure to handle cancelling action when the request is cancelled
    @discardableResult
    func request(parameters: ParameterType?, completion: @escaping (Bool, DataType?, Error?) -> Void) -> CancelHandler?
}
