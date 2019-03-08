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

//
//  IntegrationCall.swift
//  IDMCore
//
//  Created by FOLY on 8/17/16.
//  Copyright © 2016 NGUYEN CHI CONG. All rights reserved.
//

/**
 * IMPORTANT NOTE: Sequence IntegrationCall and IntegrationBatchCall only work perfectly if they are created from different Intergrators.
 */

import Foundation

public enum NextState {
    case success
    case error
    case completion
}

public class IntegrationCall<ModelType> {
    fileprivate var doBeginning: (() -> ())?
    fileprivate var doSuccess: ((ModelType?) -> ())?
    fileprivate var doProgress: ((ModelType?) -> ())?
    fileprivate var doError: ((Error?) -> ())?
    fileprivate var doCompletion: (() -> ())?
    fileprivate var doCall: ((IntegrationCall<ModelType>) -> ())?
    
    public fileprivate(set) var idenitifier: String
    
    fileprivate(set) var ignoreUnknownError: Bool = true
    
    fileprivate(set) var retryCount: Int = 0
    fileprivate(set) var retryDelay: TimeInterval = 0
    fileprivate(set) var silentRetry: Bool = true
    fileprivate(set) var retryCondition: ((Error?) -> Bool)?
    
    internal var retryErrorBlock: ((Error?) -> ())? // retryErrorBlock is higher priority than retryBlock
    internal var retryBlock: (() -> ())?
    
    fileprivate(set) var callQueue: IntegrationCallQueue = .serial
    fileprivate(set) var callDelay: Double = 0
    
    public internal(set) var integratorIndentifier: String = String()
    
    init() {
        idenitifier = ProcessInfo.processInfo.globallyUniqueString
        //        #if DEBUG
        //            print("Created integration call: \(idenitifier)")
        //        #endif
    }
    
    deinit {
        retryErrorBlock = nil
        retryBlock = nil
        
//        #if DEBUG
//            print("\(self): Released integration call \(idenitifier)")
//        #endif
    }
    
    /*********************************************************************************/
    
    // MARK: - Getters
    
    /*********************************************************************************/
    
    func handleError(error: Error?) {
        if ignoreUnknownError {
            if error == nil {
                retryErrorBlock = nil
                retryBlock = nil
//                print("*** an error nil was ignored ***")
                return
            }
        }
        
        let internalError = onError
        if let condition = retryCondition, condition(error) == false {
            retryErrorBlock = nil
            retryBlock = nil
            internalError?(error)
            return
        }
        
        guard retryCount > 0 else {
            retryErrorBlock = nil
            retryBlock = nil
            internalError?(error)
            return
        }
        if !silentRetry {
            internalError?(error)
        }
        retryCount -= 1
        //        print("Retry integration call \(idenitifier): -> \(retryCount)")
        
        if let block = retryErrorBlock {
            if retryCount == 0 {
                retryErrorBlock = nil
            }
            block(error)
        } else if let block = retryBlock {
            if retryCount == 0 {
                retryBlock = nil
            }
            block()
        } else {
            call(queue: callQueue, delay: retryDelay)
        }
    }
    
    func handleSuccess(model: ModelType?) {
        if let delayObject = model as? DelayingCompletionProtocol {
            if delayObject.isDelaying {
                if let process = doProgress {
                    process(model)
                } else {
                    print("You should set onProcess for IntegrationCall to monitor processing such as display progress and so on")
                }
            } else {
                doSuccess?(model)
            }
        } else {
            doSuccess?(model)
        }
    }
    
    var onError: ((Error?) -> ())? {
        return doError
    }
    
    var onBeginning: (() -> ())? {
        return doBeginning
    }
    
    var onSuccess: ((ModelType?) -> ())? {
        return doSuccess
    }
    
    var onCompletion: (() -> ())? {
        return doCompletion
    }
    
    /*********************************************************************************/
    
    // MARK: - Execute
    
    /*********************************************************************************/
    
    func doCall(_ handler: ((IntegrationCall<ModelType>) -> ())?) {
        doCall = handler
    }
    
    public func onBeginning(_ handler: (() -> ())?) -> Self {
        doBeginning = handler
        return self
    }
    
    public func onSuccess(_ handler: ((ModelType?) -> ())?) -> Self {
        doSuccess = { [weak self] result in
            guard let self = self else {
                return
            }
            self.retryErrorBlock = nil
            self.retryBlock = nil
            handler?(result)
        }
        return self
    }
    
    public func onError(_ handler: ((Error?) -> ())?) -> Self {
        doError = handler
        return self
    }
    
    public func onCompletion(_ handler: (() -> ())?) -> Self {
        doCompletion = handler
        return self
    }
    
    public func call(queue: IntegrationCallQueue = .serial, delay: Double = 0) {
        callQueue = queue
        callDelay = delay
        callQueue.dispatchQueue.asyncAfter(deadline: .now() + delay) {
            self.doCall?(self)
        }
    }
    
    public func call<Result>(dependOn requiredCall: IntegrationCall<Result>,
                             with state: NextState = .completion,
                             queue: IntegrationCallQueue = .serial,
                             delay: Double = 0) {
        callQueue = queue
        callDelay = delay
        requiredCall.next(state: state, integrationCall: self).call(queue: queue, delay: delay)
    }
    
    /*********************************************************************************/
    
    // MARK: - Retry
    
    /*********************************************************************************/
    
    /**
     * Set up options to retry if the call fatal error
     * silent = true: implicit don't show error message when retry is performing
     * silent = false: show error message when retry is performing
     */
    
    public func retry(_ count: Int,
                      delay: TimeInterval = 0.3,
                      silent: Bool = true,
                      condition: ((Error?) -> Bool)? = nil) -> Self {
        retryCount = count
        silentRetry = silent
        retryDelay = delay
        retryCondition = condition
        return self
    }
    
    public func retryCall<Result>(_ integrationCall: IntegrationCall<Result>, state: NextState = .completion) -> Self {
        retryBlock = nil
        
        let newCall = integrationCall.next(state: state, integrationCall: self)
        
        switch state {
        case .error, .success:
            _ = newCall.next(state: .completion) { [weak self] _ in
                self?.retryErrorBlock = nil
                self?.retryBlock = nil
            }
        default:
            break
        }
        
        let queue = callQueue
        let delay = callDelay
        retryBlock = {
            newCall.call(queue: queue, delay: delay)
        }
        return self
    }
    
    public func retryIntegrator<P, R>(_ integrator: AbstractIntegrator<P, R>,
                                      state: NextState = .completion,
                                      configuration: ((IntegrationCall<R>) -> ())? = nil) -> Self where P: Error {
        retryErrorBlock = nil
        let queue = callQueue
        let delay = callDelay
        
        retryErrorBlock = { [weak self] err in
            guard let this = self else { return }
            let param = err as? P
            let newCall = integrator.prepareCall(parameters: param)
            configuration?(newCall)
            
            switch state {
            case .error, .success:
                _ = newCall.next(state: .completion) { [weak self] _ in
                    self?.retryErrorBlock = nil
                    self?.retryBlock = nil
                }
            default:
                break
            }
            
            _ = newCall.next(state: state, integrationCall: this)
            newCall.call(queue: queue, delay: delay)
        }
        return self
    }
    
    /**
     * Set ignoreUnknownError to ignore unknown errors, this will prevent to display unexpected error messages
     * Eg: cancel action will set error = nil
     */
    
    public func ignoreUnknownError(_ ignoreUnknownError: Bool = true) -> Self {
        self.ignoreUnknownError = ignoreUnknownError
        return self
    }
    
    /*********************************************************************************/
    
    // MARK: - Advance Next
    
    /*********************************************************************************/
    
    public func next<Result>(state: NextState = .completion, integrationCall: IntegrationCall<Result>) -> Self {
        let queue = callQueue
        let delay = callDelay
        switch state {
        case .success:
            let success = doSuccess
            doSuccess = { result in
                success?(result)
                integrationCall.call(queue: queue, delay: delay)
            }
            
        case .error:
            let block = doError
            doError = { error in
                block?(error)
                integrationCall.call(queue: queue, delay: delay)
            }
            
        case .completion:
            let block = doCompletion
            doCompletion = {
                block?()
                integrationCall.call(queue: queue, delay: delay)
            }
        }
        
        return self
    }
    
    public func transform<Result>(nextState: NextState = .completion, integrationCall: IntegrationCall<Result>) -> IntegrationCall<Result> {
        let queue = callQueue
        let delay = callDelay
        switch nextState {
        case .success:
            let success = doSuccess
            doSuccess = { result in
                success?(result)
                integrationCall.call(queue: queue, delay: delay)
            }
            
        case .error:
            let block = doError
            doError = { error in
                block?(error)
                integrationCall.call(queue: queue, delay: delay)
            }
            
        case .completion:
            let block = doCompletion
            doCompletion = {
                block?()
                integrationCall.call(queue: queue, delay: delay)
            }
        }
        
        return integrationCall
    }
    
    public func next(state: NextState = .completion, nextBlock: ((Result<ModelType>?) -> ())? = nil) -> Self {
        switch state {
        case .success:
            let success = doSuccess
            doSuccess = { result in
                success?(result)
                nextBlock?(Result.success(result))
            }
            
        case .error:
            let block = doError
            doError = { error in
                block?(error)
                nextBlock?(Result.failure(error))
            }
            
        case .completion:
            let block = doCompletion
            doCompletion = {
                block?()
                nextBlock?(nil)
            }
        }
        
        return self
    }
    
    public func nextTo<Parameter, ResultType>(state: NextState = .completion,
                                              integrator: AbstractIntegrator<Parameter, ResultType>,
                                              parametersBuilder: ((Result<ModelType>?) -> Parameter?)? = nil,
                                              configuration: ((IntegrationCall<ResultType>, Result<ModelType>?) -> ())? = nil) -> Self {
        let queue = callQueue
        let delay = callDelay
        switch state {
        case .success:
            let success = doSuccess
            doSuccess = { result in
                success?(result)
                let wrapped = Result<ModelType>.success(result)
                let parameters = parametersBuilder?(wrapped)
                let integrationCall = integrator.prepareCall(parameters: parameters)
                configuration?(integrationCall, Result.success(result))
                integrationCall.call(queue: queue, delay: delay)
            }
            
        case .error:
            let block = doError
            doError = { error in
                block?(error)
                let wrapped = Result<ModelType>.failure(error)
                let parameters = parametersBuilder?(wrapped)
                let integrationCall = integrator.prepareCall(parameters: parameters)
                configuration?(integrationCall, Result.failure(error))
                integrationCall.call(queue: queue, delay: delay)
            }
            
        case .completion:
            let block = doCompletion
            doCompletion = {
                block?()
                let parameters = parametersBuilder?(nil)
                let integrationCall = integrator.prepareCall(parameters: parameters)
                configuration?(integrationCall, nil)
                integrationCall.call(queue: queue, delay: delay)
            }
        }
        
        return self
    }
    
    public func transformNextTo<Parameter, ResultType>(state: NextState = .completion,
                                                       integrator: AbstractIntegrator<Parameter, ResultType>,
                                                       parametersBuilder: ((Result<ModelType>?) -> Parameter?)? = nil) -> IntegrationCall<ResultType> {
        let queue = callQueue
        let delay = callDelay
        switch state {
        case .success:
            let success = doSuccess
            var fireCall = integrator.prepareCall()
            doSuccess = { result in
                success?(result)
                let wrapped = Result<ModelType>.success(result)
                let parameters = parametersBuilder?(wrapped)
                let newCall = integrator.prepareCall(parameters: parameters)
                
                newCall.doBeginning = fireCall.onBeginning
                newCall.doSuccess = fireCall.onSuccess
                newCall.doError = fireCall.onError
                newCall.doCompletion = fireCall.onCompletion
                
                fireCall = newCall
                
                fireCall.call(queue: queue, delay: delay)
            }
            return fireCall
            
        case .error:
            let block = doError
            var fireCall = integrator.prepareCall()
            doError = { error in
                block?(error)
                let wrapped = Result<ModelType>.failure(error)
                let parameters = parametersBuilder?(wrapped)
                let newCall = integrator.prepareCall(parameters: parameters)
                
                newCall.doBeginning = fireCall.onBeginning
                newCall.doSuccess = fireCall.onSuccess
                newCall.doError = fireCall.onError
                newCall.doCompletion = fireCall.onCompletion
                
                fireCall = newCall
                
                fireCall.call(queue: queue, delay: delay)
            }
            return fireCall
            
        case .completion:
            let block = doCompletion
            var fireCall = integrator.prepareCall()
            doCompletion = {
                block?()
                let parameters = parametersBuilder?(nil)
                let newCall = integrator.prepareCall(parameters: parameters)
                
                newCall.doBeginning = fireCall.onBeginning
                newCall.doSuccess = fireCall.onSuccess
                newCall.doError = fireCall.onError
                newCall.doCompletion = fireCall.onCompletion
                
                fireCall = newCall
                
                fireCall.call(queue: queue, delay: delay)
            }
            return fireCall
        }
    }
    
    public func forwardSuccess<Result>(callBuilder: @escaping (ModelType?) -> IntegrationCall<Result>) -> Self {
        let success = doSuccess
        let queue = callQueue
        let delay = callDelay
        
        doSuccess = { result in
            success?(result)
            let next = callBuilder(result)
            next.call(queue: queue, delay: delay)
        }
        return self
    }
    
    public func forwardError<Result>(callBuilder: @escaping (Error?) -> IntegrationCall<Result>) -> Self {
        let block = doError
        let queue = callQueue
        let delay = callDelay
        
        doError = { error in
            block?(error)
            let next = callBuilder(error)
            next.call(queue: queue, delay: delay)
        }
        
        return self
    }
    
    /*********************************************************************************/
    
    // MARK: - Manually next
    
    /*********************************************************************************/
    
    public func nextSuccessTo<Parameter, Result>(integrator: AbstractIntegrator<Parameter, Result>,
                                                 parametersBuilder: ((ModelType?) -> Parameter?)? = nil,
                                                 configuration: ((IntegrationCall<Result>, ModelType?) -> ())? = nil) -> Self {
        let success = doSuccess
        let queue = callQueue
        let delay = callDelay
        
        doSuccess = { result in
            success?(result)
            let parameters = parametersBuilder?(result)
            let next = integrator.prepareCall(parameters: parameters)
            configuration?(next, result)
            next.call(queue: queue, delay: delay)
        }
        
        return self
    }
    
    public func forwardSuccessTo<Result>(integrator: AbstractIntegrator<ModelType, Result>,
                                         configuration: ((IntegrationCall<Result>, ModelType?) -> ())? = nil) -> Self {
        let success = doSuccess
        let queue = callQueue
        let delay = callDelay
        
        doSuccess = { result in
            success?(result)
            let next = integrator.prepareCall(parameters: result)
            configuration?(next, result)
            next.call(queue: queue, delay: delay)
        }
        return self
    }
    
    public func nextErrorTo<Parameter, Result>(integrator: AbstractIntegrator<Parameter, Result>,
                                               parametersBuilder: ((Error?) -> Parameter?)? = nil,
                                               configuration: ((IntegrationCall<Result>, Error?) -> ())? = nil) -> Self {
        let block = doError
        let queue = callQueue
        let delay = callDelay
        
        doError = { error in
            block?(error)
            let parameters = parametersBuilder?(error)
            let next = integrator.prepareCall(parameters: parameters)
            configuration?(next, error)
            next.call(queue: queue, delay: delay)
        }
        
        return self
    }
    
    public func forwardErrorTo<Result>(integrator: AbstractIntegrator<Error, Result>,
                                       configuration: ((IntegrationCall<Result>, Error?) -> ())? = nil) -> Self {
        let block = doError
        let queue = callQueue
        let delay = callDelay
        
        doError = { error in
            block?(error)
            let next = integrator.prepareCall(parameters: error)
            configuration?(next, error)
            next.call(queue: queue, delay: delay)
        }
        
        return self
    }
    
    public func nextCompletionTo<Parameter, Result>(integrator: AbstractIntegrator<Parameter, Result>,
                                                    parameters: Parameter? = nil,
                                                    configuration: ((IntegrationCall<Result>) -> ())? = nil) -> Self {
        let block = doCompletion
        let queue = callQueue
        let delay = callDelay
        
        doCompletion = {
            block?()
            let next = integrator.prepareCall(parameters: parameters)
            configuration?(next)
            next.call(queue: queue, delay: delay)
        }
        return self
    }
    
    /*********************************************************************************/
    
    // MARK: - ThenRecall
    
    /*********************************************************************************/
    
    @discardableResult
    public func thenRecall<DataProvider, Model>(with integrator: Integrator<DataProvider, Model, ModelType>,
                                                parameters: DataProvider.ParameterType? = nil) -> Self {
        let beginBlock = doBeginning
        let successBlock = doSuccess
        let block = doCompletion
        let queue = callQueue
        let delay = callDelay
        
        doCompletion = {
            block?()
            let next: IntegrationCall<ModelType> = integrator.prepareCall(parameters: parameters)
            next.doBeginning = beginBlock
            next.doCompletion = block
            next.doSuccess = successBlock
            next.call(queue: queue, delay: delay)
        }
        return self
    }
}

extension IntegrationCall where ModelType: DelayingCompletionProtocol {
    public func onProgress(_ handler: ((ModelType?) -> ())?) -> Self {
        doProgress = handler
        return self
    }
}

infix operator -->: AdditionPrecedence
infix operator ->>: AdditionPrecedence
infix operator -*>: AdditionPrecedence

infix operator ~->: AdditionPrecedence
infix operator ~>>: AdditionPrecedence
infix operator ~*>: AdditionPrecedence

public func --> <R1, R2>(left: IntegrationCall<R1>, right: IntegrationCall<R2>) -> IntegrationCall<R1> {
    return left.next(state: .completion, integrationCall: right)
}

public func ->> <R1, R2>(left: IntegrationCall<R1>, right: IntegrationCall<R2>) -> IntegrationCall<R1> {
    return left.next(state: .success, integrationCall: right)
}

public func -*> <R1, R2>(left: IntegrationCall<R1>, right: IntegrationCall<R2>) -> IntegrationCall<R1> {
    return left.next(state: .error, integrationCall: right)
}

public func ~-> <R1, R2>(left: IntegrationCall<R1>, right: IntegrationCall<R2>) -> IntegrationCall<R2> {
    return left.transform(nextState: .completion, integrationCall: right)
}

public func ~>> <R1, R2>(left: IntegrationCall<R1>, right: IntegrationCall<R2>) -> IntegrationCall<R2> {
    return left.transform(nextState: .success, integrationCall: right)
}

public func ~*> <R1, R2>(left: IntegrationCall<R1>, right: IntegrationCall<R2>) -> IntegrationCall<R2> {
    return left.transform(nextState: .error, integrationCall: right)
}

public func == <R>(lhs: IntegrationCall<R>, rhs: IntegrationCall<R>) -> Bool {
    return lhs.idenitifier == rhs.idenitifier
}

extension IntegrationCall {
    public func isSameIntegrator<R>(with other: IntegrationCall<R>) -> Bool {
        return integratorIndentifier == other.integratorIndentifier
    }
}
