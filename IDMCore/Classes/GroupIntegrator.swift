//
//  GroupIntegrator.swift
//  IDMCore
//
//  Created by FOLY on 12/28/18.
//

import Foundation

public enum GroupIntegratingSuccessFilterType {
    case `default`
    case allSuccess
}

open class GroupIntegratingDataProvider<I: IntegratorProtocol>: DataProviderProtocol {
    public struct WrappedError: Error {
        public var result: [Result<I.GResultType>]
        public var errors: [Error] {
            let errorItems = result.compactMap { (item) -> Error? in
                switch item {
                case .failure(let er):
                    return er
                default:
                    return nil
                }
            }
            return errorItems
        }
    }
    
    public private(set) var internalIntegrators: [I]
    public private(set) var queue: DispatchQueue
    
    public var successFilterType: GroupIntegratingSuccessFilterType = .default
    
    private var integratorCreator: (() -> I)
    
    public init(creator: @escaping (() -> I), requestQueue: DispatchQueue = .main) {
        integratorCreator = creator
        internalIntegrators = []
        queue = requestQueue
    }
    
    public func request(parameters: [I.GParameterType?]?,
                        completion: @escaping (Bool, [Result<I.GResultType>]?, Error?) -> Void) -> CancelHandler? {
        guard let params = parameters, params.count > 0 else {
            completion(true, nil, nil)
            return nil
        }
        
        let creator = integratorCreator
        internalIntegrators = params.map { (_) -> I in
            return creator()
        }
        
        var calls: [IntegrationCall<I.GResultType>] = []
        
        for (idx, param) in params.enumerated() {
            let integrator = internalIntegrators[idx]
            
            let newCall = integrator.prepareCall(parameters: param)
            calls.append(newCall)
        }
        
        let filterType = successFilterType
        calls.call(queue: queue, delay: 0.1) { result in
            switch filterType {
            case .allSuccess:
                let fails = result.filter { (item) -> Bool in
                    switch item {
                    case .failure:
                        return true
                    default:
                        return false
                    }
                }
                
                let success = fails.count > 0
                if success {
                    completion(true, result, nil)
                } else {
                    let err = WrappedError(result: result)
                    completion(false, nil, err)
                }
            default:
                completion(true, result, nil)
            }
        }
        
        return { [weak self] in
            guard let self = self else { return }
            self.cancel()
        }
    }
    
    private func cancel() {
        internalIntegrators.forEach { integrator in
            integrator.cancel()
        }
        internalIntegrators = []
    }
}

open class GroupIntegrator<I: IntegratorProtocol>: AmazingIntegrator<GroupIntegratingDataProvider<I>> {
    public init(creator: @escaping (() -> I),
                successFilterType: GroupIntegratingSuccessFilterType = .default,
                requestQueue: DispatchQueue = .main) {
        let provider = GroupIntegratingDataProvider<I>.init(creator: creator, requestQueue: requestQueue)
        provider.successFilterType = successFilterType
        super.init(dataProvider: provider, executingType: .only)
    }
}
