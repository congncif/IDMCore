//
//  BlockDataProvider.swift
//  IDMCore
//
//  Created by FOLY on 1/4/19.
//

import Foundation

/** BlockDataProvider is a synchronous result data provider which created to be compatible to IDM data flow. */

open class BlockDataProvider<P, D>: DataProviderProtocol {
    public typealias ParameterType = P
    public typealias DataType = D

    public typealias RequestFunction = (P?) throws -> D?

    fileprivate var block: RequestFunction

    public init(_ block: @escaping RequestFunction) {
        self.block = block
    }

    open func request(parameters: ParameterType?, completionResult: @escaping (ResultType) -> Void) -> CancelHandler? {
        return request(parameters: parameters) { success, data, error in
            var result: ResultType
            if success {
                result = .success(data)
            } else if let error = error {
                result = .failure(error)
            } else {
                result = .failure(UnknownError.default)
            }
            completionResult(result)
        }
    }

    open func request(parameters: P?, completion: @escaping (Bool, D?, Error?) -> Void) -> CancelHandler? {
        do {
            let data = try block(parameters)
            completion(true, data, nil)
        } catch let ex {
            completion(false, nil, ex)
        }
        return nil
    }
}

open class BlockIntegrator<P, D>: AmazingIntegrator<BlockDataProvider<P, D>> {
    public init(_ block: @escaping BlockDataProvider<P, D>.RequestFunction) {
        let provider = BlockDataProvider(block)
        super.init(dataProvider: provider, executingType: .only)
    }
}
