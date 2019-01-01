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
    
    class InternalWorkItem: NSObject {
        var parameter: I.GParameterType?
        var integrator: I
        
        init(parameter: I.GParameterType?, creator: (() -> I)) {
            self.parameter = parameter
            integrator = creator()
        }
        
        func buildIntegrationCall() -> IntegrationCall<I.GResultType> {
            return integrator.prepareCall(parameters: parameter)
        }
    }
    
    // mutable state
    private var workItems: [InternalWorkItem]
    
    // config
    private var integratorCreator: (() -> I)
    
    public var queue: IntegrationCallQueue
//    public var maxConcurrent: Int = 3 {
//        didSet {
//            guard maxConcurrent > 0 else {
//                fatalError("Max concurrent must be greater than 0")
//            }
//        }
//    }
    
    public var successFilterType: GroupIntegratingSuccessFilterType = .default
    
    public init(creator: @escaping (() -> I), requestQueue: IntegrationCallQueue = .main) {
        integratorCreator = creator
        
        queue = requestQueue
        
        workItems = []
    }
    
    public func request(parameters: [I.GParameterType?]?,
                        completion: @escaping (Bool, [Result<I.GResultType>]?, Error?) -> Void) -> CancelHandler? {
        guard let params = parameters, params.count > 0 else {
            completion(true, nil, nil)
            return nil
        }
        
        let creator = integratorCreator
        workItems = params.map { (p) -> InternalWorkItem in
            InternalWorkItem(parameter: p, creator: creator)
        }
        
        let calls = workItems.map { $0.buildIntegrationCall() }
        
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
        workItems.forEach { item in
            item.integrator.cancel()
        }
        workItems = []
    }
}

open class GroupIntegrator<I: IntegratorProtocol>: AmazingIntegrator<GroupIntegratingDataProvider<I>> {
    public init(creator: @escaping (() -> I),
                successFilterType: GroupIntegratingSuccessFilterType = .default,
                requestQueue: IntegrationCallQueue = .main) {
        let provider = GroupIntegratingDataProvider<I>.init(creator: creator, requestQueue: requestQueue)
        provider.successFilterType = successFilterType
        super.init(dataProvider: provider, executingType: .only)
    }
}
