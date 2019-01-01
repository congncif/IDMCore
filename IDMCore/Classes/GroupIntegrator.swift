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
    
    internal class InternalWorkItem: NSObject {
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
    
    internal class InternalOperation: Operation {
        var workItem: InternalWorkItem
        var completion: (Result<I.GResultType>) -> Void
        var queue: IntegrationCallQueue
        
        init(workItem: InternalWorkItem,
             queue: IntegrationCallQueue,
             completion: @escaping (Result<I.GResultType>) -> Void) {
            self.workItem = workItem
            self.completion = completion
            self.queue = queue
        }
        
        override func main() {
            var result: Result<I.GResultType> = Result<I.GResultType>.failure(nil)
            
            guard !isCancelled else {
                completion(result)
                return
            }
            let call = workItem.buildIntegrationCall()
            let semaphore = DispatchSemaphore(value: 0)
            
            call
                .next(state: .success, nextBlock: { value in
                    if let data = value {
                        result = data
                    }
                })
                .next(state: .error, nextBlock: { error in
                    if let data = error {
                        result = data
                    }
                })
                .next(state: .completion, nextBlock: { _ in
                    semaphore.signal()
                })
                .call(queue: queue)
            
            _ = semaphore.wait(timeout: .distantFuture)
            
            completion(result)
        }
    }
    
    // mutable state
    private var workItems: [InternalWorkItem]
    
    private lazy var runningQueue: OperationQueue = {
        OperationQueue()
    }()
    
    // config
    private var integratorCreator: (() -> I)
    
    public private(set) var queue: IntegrationCallQueue = .main
    
    public var usingIntegrationBatchCall: Bool = false
    public var successFilterType: GroupIntegratingSuccessFilterType = .default
    public var maxConcurrent: Int = 3 {
        didSet {
            guard maxConcurrent > 0 else {
                fatalError("Max concurrent must be greater than 0")
            }
            assert(usingIntegrationBatchCall == false, "maxConcurrent is only valid when usingIntegrationBatchCall set to false")
        }
    }
    
    public init(creator: @escaping (() -> I), requestOn queue: IntegrationCallQueue = .main) {
        integratorCreator = creator
        self.queue = queue
        workItems = []
    }
    
    public func request(parameters: [I.GParameterType?]?,
                        completion: @escaping (Bool, [Result<I.GResultType>]?, Error?) -> Void) -> CancelHandler? {
        guard let params = parameters, params.count > 0 else {
            completion(true, nil, nil)
            return nil
        }
        
        func performCompletion(_ completion: @escaping (Bool, [Result<I.GResultType>]?, Error?) -> Void,
                               result: [Result<I.GResultType>],
                               filterType: GroupIntegratingSuccessFilterType) {
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
        
        let creator = integratorCreator
        workItems = params.map { (p) -> InternalWorkItem in
            InternalWorkItem(parameter: p, creator: creator)
        }
        
        if usingIntegrationBatchCall {
            let calls = workItems.map { $0.buildIntegrationCall() }
            let filterType = successFilterType
            calls.call(queue: queue, delay: 0.1) { result in
                performCompletion(completion, result: result, filterType: filterType)
            }
        } else {
            let group = DispatchGroup()
            var results: [Result<I.GResultType>] = []
            let requestQueue = queue
            
            let tasks = workItems.map { (item) -> InternalOperation in
                InternalOperation(workItem: item, queue: requestQueue) { result in
                    requestQueue.dispatchQueue.async {
                        results.append(result)
                        group.leave()
                    }
                }
            }
            
            runningQueue.maxConcurrentOperationCount = maxConcurrent
            
            for task in tasks {
                group.enter()
                runningQueue.addOperation(task)
            }
            
            let filterType = successFilterType
            group.notify(queue: queue.dispatchQueue) {
                performCompletion(completion, result: results, filterType: filterType)
            }
        }
        
        return { [weak self] in
            guard let self = self else { return }
            self.cancel()
        }
    }
    
    private func cancel() {
        runningQueue.cancelAllOperations()
        
        workItems.forEach { item in
            item.integrator.cancel()
        }
        workItems = []
    }
}

open class GroupIntegrator<I: IntegratorProtocol>: AmazingIntegrator<GroupIntegratingDataProvider<I>> {
    public init(creator: @escaping (() -> I), requestOn queue: IntegrationCallQueue = .main) {
        let provider = GroupIntegratingDataProvider<I>.init(creator: creator, requestOn: queue)
        super.init(dataProvider: provider, executingType: .only)
    }
}
