//
//  IntegrationCall.swift
//  IDMCore
//
//  Created by FOLY on 8/17/16.
//  Copyright © 2016 NGUYEN CHI CONG. All rights reserved.
//

import Foundation

public enum NextState {
    case success
    case error
    case completion
}

class IntegrationCallManager {
    static let shared = IntegrationCallManager()
    
    var calls: [String: Int] = [:]
    
    func add(id: String, count: Int) {
        calls[id] = count
    }
    
    func remove(id: String) {
        calls.removeValue(forKey: id)
    }
    
    func retryCount(for id: String) -> Int {
        guard let value = calls[id] else{
            return 0
        }
        return value
    }
    
    func retry(with id: String) {
        guard let value = calls[id] else{
            return
        }
        if value > 0 {
            let newValue = value - 1
            calls[id] = newValue
        }
    }
}

public class IntegrationCall<ModelType> {
    
    fileprivate var doBeginning: (()->())?
    fileprivate var doSuccess: ((ModelType?)->())?
    fileprivate var doError: ((Error?)->())?
    fileprivate var doCompletion: (()->())?
    fileprivate var doCall: ((IntegrationCall<ModelType>) -> ())?
    
    fileprivate var retryCount: Int = 0
    fileprivate var retryDelay: TimeInterval = 0
    fileprivate var silentRetry: Bool = true
    fileprivate var ignoreUnknownError: Bool = true
    fileprivate var idenitifier: String
    
    init() {
        idenitifier = ProcessInfo.processInfo.globallyUniqueString
        //        print("Created integration call: \(idenitifier)")
    }
    
    deinit {
        //        print("Released integration call \(idenitifier)")
    }
    
    /*********************************************************************************/
    //MARK: - Getters
    /*********************************************************************************/
    
    func handleError(error: Error?) {
        if ignoreUnknownError {
            if error == nil {
                return
            }
        }
        
        let internalError = onError
        //        let retryCount = IntegrationCallManager.shared.retryCount(for: id)
        
        guard retryCount > 0 else {
            internalError?(error)
            return
        }
        //        IntegrationCallManager.shared.retry(with: id)
        
        if !silentRetry {
            internalError?(error)
        }
        retryCount -= 1
        //        print("Retry integration call \(idenitifier): -> \(retryCount)")
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + retryDelay, execute: call)
    }
    
    var onError: ((Error?)->())? {
        return doError
    }
    
    var onBeginning: (()->())? {
        return doBeginning
    }
    
    var onSuccess: ((ModelType?)->())? {
        return doSuccess
    }
    
    var onCompletion: (()->())? {
        return doCompletion
    }
    
    
    /*********************************************************************************/
    //MARK: - Execute
    /*********************************************************************************/
    
    func doCall(_ handler: ((IntegrationCall<ModelType>)->())?) {
        self.doCall = handler
    }
    
    @discardableResult
    public func onBeginning(_ handler: (()->())?) -> Self {
        doBeginning = handler
        return self
    }
    
    @discardableResult
    public func onSuccess(_ handler: ((ModelType?)->())?) -> Self {
        doSuccess = handler
        return self
    }
    
    @discardableResult
    public func onError(_ handler: ((Error?)->())?) -> Self {
        doError = handler
        return self
    }
    
    @discardableResult
    public func onCompletion(_ handler: (()->())?) -> Self {
        doCompletion = handler
        return self
    }
    
    public func call() {
        doCall?(self)
    }
    
    public func call<Result>(dependOn requiredCall: IntegrationCall<Result>, with state: NextState = .completion) {
        requiredCall.next(state: state, integrationCall: self).call()
    }
    
    
    /*********************************************************************************/
    //MARK: - Retry
    /*********************************************************************************/
    
    @discardableResult
    public func retry(_ retryCount: Int, delay: TimeInterval = 0.3, silent: Bool = true) -> Self {
        //        IntegrationCallManager.shared.add(id: idenitifier, count: retryCount)
        self.retryCount = retryCount
        self.silentRetry = silent
        self.retryDelay = delay
        return self
    }
    
    @discardableResult
    public func ignoreUnknownError(_ ignoreUnknownError: Bool = true) -> Self {
        self.ignoreUnknownError = ignoreUnknownError
        return self
    }
    
    /*********************************************************************************/
    //MARK: - Advance Next
    /*********************************************************************************/
    
    @discardableResult
    public func next<Result>(state: NextState = .completion, integrationCall: IntegrationCall<Result>) -> Self {
        switch state {
        case .success:
            let success = doSuccess
            doSuccess = { result in
                success?(result)
                integrationCall.call()
            }
            
        case .error:
            let block = doError
            doError = { error in
                block?(error)
                integrationCall.call()
            }
            
        case .completion:
            let block = doCompletion
            doCompletion = {
                block?()
                integrationCall.call()
            }
        }
        
        return self
    }
    
    @discardableResult
    public func next<DataProvider, Model, Result>(
        state: NextState = .completion,
        integrator: Integrator<DataProvider, Model, Result>,
        parameters: DataProvider.ParameterType? = nil,
        configuration: @escaping(IntegrationCall<Result>)->() = {_ in}) -> Self {
        
        switch state {
        case .success:
            let success = doSuccess
            doSuccess = { result in
                success?(result)
                let integrationCall = integrator.prepareCall(parameters: parameters)
                configuration(integrationCall)
                integrationCall.call()
            }
            
        case .error:
            let block = doError
            doError = { error in
                block?(error)
                let integrationCall = integrator.prepareCall(parameters: parameters)
                configuration(integrationCall)
                integrationCall.call()
            }
            
        case .completion:
            let block = doCompletion
            doCompletion = {
                block?()
                let integrationCall = integrator.prepareCall(parameters: parameters)
                configuration(integrationCall)
                integrationCall.call()
            }
        }
        
        return self
        
    }
    
    public func forwardSuccess<Result>(callBuilder: @escaping (ModelType?) -> IntegrationCall<Result>) -> Self {
        let success = doSuccess
        doSuccess = { result in
            success?(result)
            let next = callBuilder(result)
            next.call()
        }
        return self
    }
    
    public func forwardError<Result>(callBuilder: @escaping (Error?) -> IntegrationCall<Result>) -> Self {
        let block = doError
        doError = { error in
            block?(error)
            let next = callBuilder(error)
            next.call()
        }
        
        return self
    }
    
    
    /*********************************************************************************/
    //MARK: - Manually next
    /*********************************************************************************/
    
    @discardableResult
    public func nextSuccess<DataProvider, Model, Result>(integrator: Integrator<DataProvider,Model,Result>,
                            parameters: DataProvider.ParameterType? = nil,
                            configuration: @escaping(IntegrationCall<Result>)->() = {_ in}) -> Self {
        
        let success = doSuccess
        doSuccess = { result in
            success?(result)
            let next = integrator.prepareCall(parameters: parameters)
            configuration(next)
            next.call()
        }
        
        return self
    }
    
    @discardableResult
    public func forwardSuccess<DataProvider, Model, Result>(integrator: Integrator<DataProvider, Model, Result>,
                               configuration: @escaping(IntegrationCall<Result>)->() = {_ in}) -> Self where DataProvider.ParameterType == ModelType {
        let success = doSuccess
        doSuccess = { result in
            success?(result)
            let next = integrator.prepareCall(parameters: result)
            configuration(next)
            next.call()
        }
        return self
    }
    
    @discardableResult
    public func nextError<DataProvider, Model, Result>(integrator: Integrator<DataProvider, Model, Result>,
                          parameters: DataProvider.ParameterType? = nil,
                          configuration: @escaping(IntegrationCall<Result>)->() = {_ in}) -> Self {
        let block = doError
        
        doError = { error in
            block?(error)
            let next = integrator.prepareCall(parameters: parameters)
            configuration(next)
            next.call()
        }
        
        return self
    }
    
    @discardableResult
    public func fowardError<DataProvider, Model, Result>(integrator: Integrator<DataProvider, Model, Result>,
                            configuration: @escaping(IntegrationCall<Result>)->() = {_ in}) -> Self where DataProvider.ParameterType == Error {
        let block = doError
        doError = { error in
            block?(error)
            let next = integrator.prepareCall(parameters: error)
            configuration(next)
            next.call()
        }
        
        return self
    }
    
    @discardableResult
    public func nextCompletion <DataProvider, Model, Result>(integrator: Integrator<DataProvider, Model, Result>,
                                parameters: DataProvider.ParameterType? = nil, configuration: @escaping(IntegrationCall<Result>)->() = {_ in}) -> Self {
        let block = doCompletion
        doCompletion = {
            block?()
            let next = integrator.prepareCall(parameters: parameters)
            configuration(next)
            next.call()
        }
        return self
    }
    
    /*********************************************************************************/
    //MARK: - ThenRecall
    /*********************************************************************************/
    
    @discardableResult
    public func thenRecall <DataProvider, Model>(with integrator: Integrator<DataProvider, Model, ModelType>,
                            parameters: DataProvider.ParameterType? = nil) -> Self {
        let beginBlock = doBeginning
        let successBlock = doSuccess
        let block = doCompletion
        
        doCompletion = {
            block?()
            let next: IntegrationCall<ModelType> = integrator.prepareCall(parameters: parameters)
            next.doBeginning = beginBlock
            next.doCompletion = block
            next.doSuccess = successBlock
            next.call()
        }
        return self
    }
    
    
}
