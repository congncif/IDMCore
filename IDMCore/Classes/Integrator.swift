//
/**
 Copyright (c) 2016 Nguyen Chi Cong

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

//  Integrator.swift
//  IDMCore
//
//  Created by NGUYEN CHI CONG on 8/31/16.
//  Copyright © 2016 NGUYEN CHI CONG. All rights reserved.
//

import Foundation

open class AbstractIntegrator<Parameter, Result>: IntegratorProtocol, Equatable {
    public typealias GParameterType = Parameter
    public typealias GResultType = Result

    public fileprivate(set) var idenitifier: String

    public init() {
        idenitifier = ProcessInfo.processInfo.globallyUniqueString
    }

    open func prepareCall(parameters _: Parameter?) -> IntegrationCall<Result> {
        assertionFailure("Abstract method needs an implementation")

        return IntegrationCall<Result>()
    }

    public static func == (lhs: AbstractIntegrator, rhs: AbstractIntegrator) -> Bool {
        return lhs.idenitifier == rhs.idenitifier
    }
}

//////////////////////////////////////////////////////////////////////////////////////
class IntegrationInfo<ModelType, ParameterType>: NSObject {
    var parameters: ParameterType?
    var loading: (() -> Void)?
    var cancel: (() -> Void)?
    var completion: ((Bool, ModelType?, Error?) -> Void)?

    init(parameters: ParameterType?, loading: (() -> Void)?, completion: ((Bool, ModelType?, Error?) -> Void)?) {
        self.parameters = parameters
        self.loading = loading
        self.completion = completion
    }
}

public enum IntegrationType {
    case `default` // All integration calls will be executed independently
    case only // Only single integration call is executed at the moment, all integration calls arrive when current call is running will be ignored
    case queue // All integration calls will be added to queue to execute
    case latest // The integration will cancel all integration call before & only execute latest integration call
}

open class Integrator<IntegrateProvider: DataProviderProtocol, IntegrateModel: ModelProtocol, IntegrateResult>: AbstractIntegrator<IntegrateProvider.ParameterType, IntegrateResult>, IntegrationProtocol where IntegrateProvider.DataType == IntegrateModel.DataType {
    public typealias GParameterType = IntegrateProvider.ParameterType
    public typealias GResultType = IntegrateResult
    public typealias DataProviderType = IntegrateProvider
    public typealias ModelType = IntegrateModel
    public typealias ResultType = IntegrateResult

    typealias CallInfo = IntegrationInfo<ResultType, ParameterType>

    open var dataProvider: DataProviderType
    open var executingType: IntegrationType
    open var noValueError: Error?

    fileprivate var debouncedFunction: Debouncer? // only valid for latest executing
    fileprivate var defaultCall = IntegrationCall<ResultType>()
    fileprivate var retryCall = IntegrationCall<ResultType>()
    fileprivate var retrySetBlock: ((IntegrationCall<ResultType>) -> Void)?
    fileprivate var executingQueue = DispatchQueue.running
    fileprivate var preparingQueue = DispatchQueue.momentum
    fileprivate var runningCallsQueue: SynchronizedArray<CallInfo>
    fileprivate var queueRunning: AtomicBool // useful for type = .queue or .only
    fileprivate var callInfosQueue: SynchronizedArray<CallInfo>

    public init(dataProvider: DataProviderType,
                modelType _: ModelType.Type,
                executingType: IntegrationType = .default) {
        self.dataProvider = dataProvider
        self.executingType = executingType
        queueRunning = AtomicBool(queue: DispatchQueue.idmConcurrent)
        callInfosQueue = SynchronizedArray<CallInfo>(queue: preparingQueue, elements: [])
        runningCallsQueue = SynchronizedArray<CallInfo>(queue: executingQueue, elements: [])

        super.init()

        switch executingType {
        case .latest:
            throttle()
        default:
            break
        }
    }

    deinit {
        retrySetBlock = nil
        cancelRunning()
    }

    fileprivate func cancelCurrentTasks() {
        for task in runningCallsQueue.compactMap({ $0 }) {
            task.cancel?()
            DispatchQueue.main.async {
                task.completion?(false, nil, nil)
            }
        }
        runningCallsQueue.removeAll()
    }

    fileprivate func resumeCurrentTask(_ task: CallInfo) {
        DispatchQueue.main.async {
            task.loading?()
        }
        let cancel = dataProvider.request(parameters: task.parameters) { [weak self] success, data, error in
            guard let this = self else {
                return
            }
            self?.finish(success: success, data: data, error: error) { [weak this] s, d, e in
                // forward results
                DispatchQueue.main.async {
                    task.completion?(s, d, e)
                }
                this?.dequeueTask(task)
            }
        }
        task.cancel = cancel
        enqueueTask(task)
    }

    fileprivate func enqueueTask(_ task: CallInfo) {
        runningCallsQueue.append(task)
    }

    fileprivate func dequeueTask(_ task: CallInfo) {
        runningCallsQueue.remove(where: { (current) -> Bool in
            task.isEqual(current)
        }, completion: { [weak self] _ in
            self?.queueRunning.value = false
            self?.executeTask()
        })
    }

    fileprivate func schedule(parameters: ParameterType?, loading: (() -> Void)? = nil, completion: ((Bool, ResultType?, Error?) -> Void)?) {
        switch executingType {
        case .latest:
            let info = IntegrationInfo(parameters: parameters, loading: loading, completion: completion)
            callInfosQueue.removeAll { [weak self] _ in
                guard let self = self else { return }
                self.callInfosQueue.append(info)
                if let executer = self.debouncedFunction {
                    DispatchQueue.main.async(execute: executer.call)
                } else {
                    self.prepareExecute()
                }
            }
            return
        case .only: // call immediately then block integrator, use queueRunning to control only call at the same time
            guard !queueRunning.value else {
                return
            }
            let info = IntegrationInfo(parameters: parameters, loading: loading, completion: completion)
            queueRunning.value = true
            resumeCurrentTask(info)
            callInfosQueue.removeAll() // ignore this queue with type .only
        default: // .default & .queue -> append calls queue
            let info = IntegrationInfo(parameters: parameters, loading: loading, completion: completion)
            callInfosQueue.append(info)
            prepareExecute()
        }
    }

    // call or extend queue calls
    fileprivate func prepareExecute() {
        guard !callInfosQueue.isEmpty else {
            return
        }
        switch executingType {
        case .latest:
            if runningCallsQueue.count > 0 {
                cancelCurrentTasks()
            }
            executeTask()

        case .default: // call calls immediately
            for info in callInfosQueue.compactMap({ $0 }) {
                resumeCurrentTask(info)
            }
            callInfosQueue.removeAll()
        default: // .queue: execute tasks by queue using queueRunning to control only call at the same time
            executeTask()
            break
        }
    }

    private var lock = NSRecursiveLock() // because executingType = .queue using recursive func to call tasks so this lock used to prevent deadlock
    fileprivate func executeTask() {
        lock.lock()
        defer { lock.unlock() }

        guard !queueRunning.value else {
            return
        }
        var info: CallInfo?
        switch executingType {
        case .latest:
            guard let _info = callInfosQueue.last else {
                return
            }
            info = _info
            callInfosQueue.removeAll()

        default:
            guard let _info = callInfosQueue.first else {
                return
            }
            info = _info
            if callInfosQueue.count > 0 {
                callInfosQueue.remove(at: 0)
            }
        }
        guard let taskInfo = info else {
            return
        }
        queueRunning.value = true
        resumeCurrentTask(taskInfo)
    }

    /*********************************************************************************/

    // MARK: - Execute

    /*********************************************************************************/

    open func execute(parameters: ParameterType? = nil, completion: ((Bool, ResultType?, Error?) -> Void)? = nil) {
        schedule(parameters: parameters,
                 loading: { [weak self] in
                     self?.defaultCall.onBeginning?()
                 },
                 completion: { [weak self] s, d, e in
                     if s {
                         self?.defaultCall.onSuccess?(d)
                     } else {
                         self?.defaultCall.onError?(e)
                     }
                     defer {
                         self?.defaultCall.onCompletion?()
                         completion?(s, d, e)
                     }
        })
    }

    open func execute(parameters: ParameterType? = nil,
                      loadingHandler: (() -> Void)?,
                      successHandler: ((ResultType?) -> Void)?,
                      failureHandler: ((Error?) -> Void)? = nil,
                      completionHandler: (() -> Void)?) {
        schedule(parameters: parameters,
                 loading: { [weak self] in
                     self?.defaultCall.onBeginning?()
                     loadingHandler?()
                 },
                 completion: { [weak self] success, model, error in
                     if success {
                         self?.defaultCall.onSuccess?(model)
                         successHandler?(model)
                     } else {
                         self?.defaultCall.onError?(error)
                         failureHandler?(error)
                     }
                     defer {
                         if let delayObject = model as? DelayingCompletionProtocol {
                             if delayObject.isDelaying {
                                 //                                print("Delaying completion: \(String(describing: delayObject)) ...")
                             } else {
                                 self?.defaultCall.onCompletion?()
                                 completionHandler?()
                             }
                         } else {
                             self?.defaultCall.onCompletion?()
                             completionHandler?()
                         }
                     }
        })
    }

    /*********************************************************************************/

    // MARK: - Default handlers

    /*********************************************************************************/
    @discardableResult
    public func throttle(delay: Double = 0.5) -> Self {
        switch executingType {
        case .latest:
            debouncedFunction?.cancel()
            debouncedFunction = nil

            if delay > 0 {
                debouncedFunction = Debouncer(delay: delay) { [weak self] in
                    self?.prepareExecute()
                }
            }
        default:
            print("\(#function) is only valid with .latest executingType")
            break
        }
        return self
    }

    @discardableResult
    public func onBeginning(_ handler: (() -> Void)?) -> Self {
        _ = defaultCall.onBeginning(handler)
        return self
    }

    @discardableResult
    public func onSuccess(_ handler: ((ResultType?) -> Void)?) -> Self {
        _ = defaultCall.onSuccess(handler)
        return self
    }

    @discardableResult
    public func onError(_ handler: ((Error?) -> Void)?) -> Self {
        _ = defaultCall.onError(handler)
        return self
    }

    @discardableResult
    public func onCompletion(_ handler: (() -> Void)?) -> Self {
        _ = defaultCall.onCompletion(handler)
        return self
    }

    @discardableResult
    public func ignoreUnknownError(_ ignoreUnknownError: Bool = true) -> Self {
        _ = defaultCall.ignoreUnknownError(ignoreUnknownError)
        return self
    }

    @discardableResult
    public func retry(_ count: Int,
                      delay: TimeInterval = 0.3,
                      silent: Bool = true,
                      condition: ((Error?) -> Bool)? = nil) -> Self {
        _ = retryCall.retry(count, delay: delay, silent: silent, condition: condition)
        return self
    }

    @discardableResult
    public func retryCall<D, M, R>(_ integrator: Integrator<D, M, R>, state: NextState = .completion, configuration: ((IntegrationCall<R>) -> Void)? = nil) -> Self {
        retrySetBlock = nil
        retrySetBlock = { call in
            let queue = call.callQueue
            let delay = call.callDelay
            let retryCall = integrator.prepareCall()
            configuration?(retryCall)
            let newCall = retryCall.next(state: state, integrationCall: call)
            call.retryBlock = {
                newCall.call(queue: queue, delay: delay)
            }
        }
        return self
    }

    @discardableResult
    public func retryCall<D, M, R>(_ integrator: Integrator<D, M, R>, state: NextState = .completion, configuration: ((IntegrationCall<R>) -> Void)? = nil) -> Self where D.ParameterType: Error {
        retrySetBlock = nil
        retrySetBlock = { call in
            call.retryIntegrator(integrator, state: state, configuration: configuration)
        }
        return self
    }

    public func resetRetryCall() {
        retryCall = IntegrationCall<ResultType>()
        retrySetBlock = nil
    }

    public func cancelRunning() {
        debouncedFunction?.cancel()
        callInfosQueue.removeAll()
        cancelCurrentTasks()

        queueRunning.value = false
    }

    /*********************************************************************************/

    // MARK: - Integration Call

    /*********************************************************************************/

    open override func prepareCall(parameters: ParameterType? = nil) -> IntegrationCall<ResultType> {
        let call = IntegrationCall<ResultType>()

        call.ignoreUnknownError(defaultCall.ignoreUnknownError)

        call.retry(retryCall.retryCount, delay: retryCall.retryDelay, silent: retryCall.silentRetry, condition: retryCall.retryCondition)

        if let block = retrySetBlock {
            block(call)
        }

        call.doCall { [weak self] inCall in
            self?.execute(parameters: parameters,
                          loadingHandler: inCall.onBeginning,
                          successHandler: { result in
                              inCall.handleSuccess(model: result)
                          },
                          failureHandler: { error in
                              inCall.handleError(error: error)
                          },
                          completionHandler: inCall.onCompletion)
        }
        call.integratorIndentifier = idenitifier
        return call
    }
}
