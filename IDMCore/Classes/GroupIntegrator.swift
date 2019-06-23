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
    public typealias ParameterType = [I.GParameterType?]
    public typealias Element = SimpleResult<I.GResultType?>
    public typealias DataType = [Element]

    public func request(parameters: ParameterType?, completionResult: @escaping (ResultType) -> Void) -> CancelHandler? {
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

    public struct WrappedError: Error {
        public var result: [Element]
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

        init(parameter: I.GParameterType?, creator: () -> I) {
            self.parameter = parameter
            integrator = creator()
        }

        func buildIntegrationCall() -> IntegrationCall<I.GResultType> {
            return integrator.prepareCall(parameters: parameter)
        }
    }

    internal class InternalOperation: Operation {
        var workItem: InternalWorkItem
        var completion: (Element) -> Void
        var queue: IntegrationCallQueue

        init(workItem: InternalWorkItem,
             queue: IntegrationCallQueue,
             completion: @escaping (Element) -> Void) {
            self.workItem = workItem
            self.completion = completion
            self.queue = queue
        }

        override func main() {
            var result: Element = .failure(UnknownError.default)

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
    private var integratorCreator: () -> I

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
                        completion: @escaping (Bool, [Element]?, Error?) -> Void) -> CancelHandler? {
        guard let params = parameters, !params.isEmpty else {
            completion(true, nil, nil)
            return nil
        }

        func performCompletion(_ completion: @escaping (Bool, [Element]?, Error?) -> Void,
                               result: [Element],
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

                let success = !fails.isEmpty
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
            var results: [Element] = []
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
