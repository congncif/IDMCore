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

open class DataProcessor<ModelType>: DataProcessingProtocol {
    open func process(data: ModelType?) {
        print("Need override function \(#function) to process data: \(String(describing: data))")
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

open class Integrator<IntegrateProvider: DataProviderProtocol, IntegrateModel: ModelProtocol, IntegrateResult>: IntegrationProtocol where IntegrateProvider.DataType == IntegrateModel.DataType {
    typealias CallInfo = IntegrationInfo<ResultType, DataProviderType.ParameterType>

    public typealias DataProviderType = IntegrateProvider
    public typealias ModelType = IntegrateModel
    public typealias ResultType = IntegrateResult

    open var dataProvider: DataProviderType
    open var executingType: IntegrationType
    open var noValueError: Error?

    fileprivate var defaultCall: IntegrationCall<ResultType> = IntegrationCall<ResultType>()
    fileprivate var infoQueue: [CallInfo] = []
    //    fileprivate var syncQueue = DispatchQueue(label: "com.if.sync-queue")
    fileprivate var mainTask: CallInfo?

    fileprivate var running: Bool = false {
        didSet {
            if running == false {
                executeTask()
            }
        }
    }

    public init(dataProvider: DataProviderType, modelType _: ModelType.Type, executingType: IntegrationType = .default) {
        self.dataProvider = dataProvider
        self.executingType = executingType
    }

    deinit {
        infoQueue.removeAll()
        cancelCurrentTask()
    }

    func cancelCurrentTask() {
        if let task = self.mainTask {
            task.cancel?()
            DispatchQueue.main.async {
                task.completion?(false, nil, nil)
            }
            mainTask = nil
            running = false
        }
    }

    func resumeCurrentTask(task: CallInfo) {
        DispatchQueue.main.async {
            task.loading?()
        }
        let cancel = dataProvider.request(parameters: task.parameters) { [weak self] success, data, error in
            guard let this = self else {
                return
            }
            self?.finish(success: success, data: data, error: error, completion: { [weak this] s, d, e in
                // forward results
                DispatchQueue.main.async {
                    task.completion?(s, d, e)
                }
                this?.mainTask = nil
                this?.running = false
            })
        }
        task.cancel = cancel
        mainTask = task
    }

    func schedule(parameters: DataProviderType.ParameterType?, loading: (() -> Void)? = nil, completion: ((Bool, ResultType?, Error?) -> Void)?) {
        switch executingType {
        case .latest:
            infoQueue.removeAll()
            let info = IntegrationInfo(parameters: parameters, loading: loading, completion: completion)
            infoQueue.append(info)
        case .only:
            guard !running else {
                return
            }
            fallthrough
        default:
            let info = IntegrationInfo(parameters: parameters, loading: loading, completion: completion)
            infoQueue.append(info)
        }
        prepareExecute()
    }

    func prepareExecute() {
        guard !infoQueue.isEmpty else {
            return
        }
        switch executingType {
        case .latest:
            if let _ = mainTask {
                cancelCurrentTask()
            } else {
                executeTask()
            }
        case .default:
            for info in infoQueue {
                resumeCurrentTask(task: info)
            }
            infoQueue.removeAll()
        default:
            executeTask()
            break
        }
    }

    private var lock = NSLock()
    func executeTask() {
        lock.lock()
        defer { lock.unlock() }

        guard !running else {
            return
        }
        var info: CallInfo?
        switch executingType {
        case .latest:
            guard let _info = infoQueue.last else {
                return
            }
            info = _info
            infoQueue.removeAll()

        default:
            guard let _info = infoQueue.first else {
                return
            }
            info = _info
            infoQueue.removeFirst()
        }
        guard let taskInfo = info else {
            return
        }
        running = true
        resumeCurrentTask(task: taskInfo)
    }

    /*********************************************************************************/

    // MARK: - Execute

    /*********************************************************************************/

    open func execute(parameters: DataProviderType.ParameterType? = nil, completion: ((Bool, ResultType?, Error?) -> Void)? = nil) {
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

    open func execute(parameters: DataProviderType.ParameterType? = nil,
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

    /*********************************************************************************/

    // MARK: - Integration Call

    /*********************************************************************************/

    public func prepareCall(parameters: DataProviderType.ParameterType? = nil) -> IntegrationCall<ResultType> {
        let call = IntegrationCall<ResultType>()
        call.doCall { [weak self] inCall in
            self?.execute(parameters: parameters, loadingHandler: inCall.onBeginning, successHandler: inCall.onSuccess, failureHandler: {
                error in
                inCall.handleError(error: error)
            }, completionHandler: inCall.onCompletion)
        }
        return call
    }
}
