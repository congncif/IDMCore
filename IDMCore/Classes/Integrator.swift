//
//  DefaultDataBinding.swift
//  IDMCore
//
//  Created by NGUYEN CHI CONG on 8/31/16.
//  Copyright © 2016 NGUYEN CHI CONG. All rights reserved.
//

import Foundation

open class DefaultDataBinding<ParameterType,ModelType>: DataBindingProtocol {
    open func bindingData(_ parameters:ParameterType?, data: ModelType?) {
        fatalError("Must overrided by subclass")
    }
}

//////////////////////////////////////////////////////////////////////////////////////
class IntegrationInfo<ModelType, ParameterType>: NSObject  {
    var parameters:ParameterType?
    var loading:(() -> ())?
    var cancel:(() -> ())?
    var completion:((Bool, ModelType?, Error?) -> ())?
    
    init(parameters: ParameterType?, loading: (() -> ())?, completion:((Bool, ModelType?, Error?) -> ())?) {
        self.parameters = parameters
        self.loading = loading
        self.completion = completion
    }
    
}

public enum IntegrationType {
    case `default`      // All integration calls will be executed independently
    case only           // Only single integration call is executed at the moment, all integration calls arrive when current call is running will be ignored
    case queue          // All integration calls will be added to queue to execute
    case latest         // The integration will cancel all integration call before & only execute latest integration call
}

open class Integrator <IntegrateProvider: DataProviderProtocol, IntegrateModel: ModelProtocol, IntegrateResult>: IntegrationProtocol where IntegrateProvider.DataType == IntegrateModel.DataType  {
    
    typealias CallInfo = IntegrationInfo<ResultType, DataProviderType.ParameterType>
    
    public typealias DataProviderType = IntegrateProvider
    public typealias ModelType = IntegrateModel
    public typealias ResultType = IntegrateResult
    
    open fileprivate(set) var dataProvider: DataProviderType
    open fileprivate(set) var executingType: IntegrationType
    
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
    
    public init(dataProvider: DataProviderType, modelType: ModelType.Type, executingType: IntegrationType = .default) {
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
            self.mainTask = nil
            self.running = false
        }
    }
    
    func resumeCurrentTask(task: CallInfo) {
        DispatchQueue.main.async {
            task.loading?()
        }
        let cancel = self.dataProvider.request(parameters: task.parameters) { [weak self] (success, data, error) in
            guard let this = self else {
                return
            }
            self?.finish(success: success, data: data, error: error, completion: { [weak this] (s, d , e) in
                //forward results
                DispatchQueue.main.async {
                    task.completion?(s,d,e)
                }
                this?.mainTask = nil
                this?.running = false
            })
        }
        task.cancel = cancel
        mainTask = task
    }
    
    func schedule(parameters:DataProviderType.ParameterType?, loading:(() -> ())? = nil, completion: ((Bool, ResultType?, Error?) -> ())?) {
        switch self.executingType {
        case .latest:
            self.infoQueue.removeAll()
            let info = IntegrationInfo(parameters: parameters, loading: loading, completion: completion)
            self.infoQueue.append(info)
        case .only:
            guard !running else {
                return
            }
            fallthrough
        default:
            let info = IntegrationInfo(parameters: parameters, loading: loading, completion: completion)
            self.infoQueue.append(info)
        }
        self.prepareExecute()
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
        self.running = true
        resumeCurrentTask(task: taskInfo)
    }
    
    /*********************************************************************************/
    //MARK: - Execute
    /*********************************************************************************/
    
    open func execute(parameters: DataProviderType.ParameterType? = nil , completion: ((Bool, ResultType?, Error?) -> ())? = nil) {
        schedule(parameters: parameters,
                 loading:{ [weak self] in
                    self?.defaultCall.onBeginning?()
            },
                 completion: { [weak self] (s, d, e) in
                    if s {
                        self?.defaultCall.onSuccess?(d)
                    }else {
                        self?.defaultCall.onError?(e)
                    }
                    defer {
                        self?.defaultCall.onCompletion?()
                        completion?(s,d,e)
                    }
        })
    }
    
    open func execute(parameters:DataProviderType.ParameterType? = nil,
                      loadingHandler: (() -> ())? ,
                      successHandler: ((ResultType?) -> ())?,
                      failureHandler: ((Error?) -> ())? = nil,
                      completionHandler: (() -> ())?)  {
        
        schedule(parameters: parameters,
                 loading: { [weak self] in
                    self?.defaultCall.onBeginning?()
                    loadingHandler?()
            },
                 completion: { [weak self] (success, model, error) in
                    if success {
                        self?.defaultCall.onSuccess?(model)
                        successHandler?(model)
                    } else {
                        self?.defaultCall.onError?(error)
                        failureHandler?(error)
                    }
                    defer {
                        self?.defaultCall.onCompletion?()
                        completionHandler?()
                    }
            }
        )
    }
    
    
    /*********************************************************************************/
    //MARK: - Default handlers
    /*********************************************************************************/
    
    @discardableResult
    public func onBeginning(_ handler: (()->())?) -> Self {
        _ = defaultCall.onBeginning(handler)
        return self
    }
    
    @discardableResult
    public func onSuccess(_ handler: ((ResultType?)->())? ) -> Self {
        _ = defaultCall.onSuccess(handler)
        return self
    }
    
    @discardableResult
    public func onError(_ handler: ((Error?)->())?) -> Self {
        _ = defaultCall.onError(handler)
        return self
    }
    
    @discardableResult
    public func onCompletion(_ handler: (()->())?) -> Self {
        _ = defaultCall.onCompletion(handler)
        return self
    }
    
    /*********************************************************************************/
    //MARK: - Integration Call
    /*********************************************************************************/
    
    public func prepareCall(parameters:DataProviderType.ParameterType? = nil) -> IntegrationCall<ResultType> {
        let call = IntegrationCall<ResultType>()
        call.doCall { [weak self] (inCall) in
            self?.execute(parameters: parameters, loadingHandler: inCall.onBeginning, successHandler: inCall.onSuccess, failureHandler: {
                error in
                inCall.handleError(error: error)
            }, completionHandler: inCall.onCompletion)
        }
        return call
    }
    
    
}
