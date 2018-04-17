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

public enum Result<Value> {
    case success(Value?)
    case failure(Error?)
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
    
    fileprivate(set) var callQueue: DispatchQueue = DispatchQueue.global()
    fileprivate(set) var callDelay: Double = 0
    
    public internal(set) weak var integrator: AnyObject?
    
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
    
    @discardableResult
    public func onBeginning(_ handler: (() -> ())?) -> Self {
        doBeginning = handler
        return self
    }
    
    @discardableResult
    public func onSuccess(_ handler: ((ModelType?) -> ())?) -> Self {
        doSuccess = { [unowned self] result in
            self.retryErrorBlock = nil
            self.retryBlock = nil
            handler?(result)
        }
        return self
    }
    
    @discardableResult
    public func onError(_ handler: ((Error?) -> ())?) -> Self {
        doError = handler
        return self
    }
    
    @discardableResult
    public func onCompletion(_ handler: (() -> ())?) -> Self {
        doCompletion = handler
        return self
    }
    
    public func call(queue: DispatchQueue = DispatchQueue.global(), delay: Double = 0) {
        callQueue = queue
        callDelay = delay
        queue.asyncAfter(deadline: .now() + delay) {
            self.doCall?(self)
        }
    }
    
    public func call<Result>(dependOn requiredCall: IntegrationCall<Result>, with state: NextState = .completion, queue: DispatchQueue = DispatchQueue.global(), delay: Double = 0) {
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
    @discardableResult
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
    
    @discardableResult
    public func retryCall<Result>(_ integrationCall: IntegrationCall<Result>, state: NextState = .completion) -> Self {
        retryBlock = nil
        
        let newCall = integrationCall.next(state: state, integrationCall: self)
        
        switch state {
        case .error, .success:
            newCall.next(state: .completion, nextBlock: { [weak self] _ in
                self?.retryErrorBlock = nil
                self?.retryBlock = nil
            })
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
    
    @discardableResult
    public func retryIntegrator<D, M, R>(_ integrator: Integrator<D, M, R>,
                                         state: NextState = .completion,
                                         configuration: ((IntegrationCall<R>) -> ())? = nil) -> Self where D.ParameterType: Error {
        retryErrorBlock = nil
        let queue = callQueue
        let delay = callDelay
        
        retryErrorBlock = { [weak self] err in
            guard let this = self else { return }
            let param = err as? D.ParameterType
            let newCall = integrator.prepareCall(parameters: param)
            configuration?(newCall)
            
            switch state {
            case .error, .success:
                newCall.next(state: .completion, nextBlock: { [weak self] _ in
                    self?.retryErrorBlock = nil
                    self?.retryBlock = nil
                })
            default:
                break
            }
            
            newCall.next(state: state, integrationCall: this)
            newCall.call(queue: queue, delay: delay)
        }
        return self
    }
    
    /**
     * Set ignoreUnknownError to ignore unknown errors, this will prevent to display unexpected error messages
     * Eg: cancel action will set error = nil
     */
    @discardableResult
    public func ignoreUnknownError(_ ignoreUnknownError: Bool = true) -> Self {
        self.ignoreUnknownError = ignoreUnknownError
        return self
    }
    
    /*********************************************************************************/
    
    // MARK: - Advance Next
    
    /*********************************************************************************/
    
    @discardableResult
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
    
    @discardableResult
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
    
    @discardableResult
    public func next<DataProvider, Model, ResultType>(state: NextState = .completion,
                                                      integrator: Integrator<DataProvider, Model, ResultType>,
                                                      parametersBuilder: ((Result<ModelType>?) -> DataProvider.ParameterType?)? = nil,
                                                      configuration: @escaping (IntegrationCall<ResultType>) -> () = { _ in }) -> Self {
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
                configuration(integrationCall)
                integrationCall.call(queue: queue, delay: delay)
            }
            
        case .error:
            let block = doError
            doError = { error in
                block?(error)
                let wrapped = Result<ModelType>.failure(error)
                let parameters = parametersBuilder?(wrapped)
                let integrationCall = integrator.prepareCall(parameters: parameters)
                configuration(integrationCall)
                integrationCall.call(queue: queue, delay: delay)
            }
            
        case .completion:
            let block = doCompletion
            doCompletion = {
                block?()
                let parameters = parametersBuilder?(nil)
                let integrationCall = integrator.prepareCall(parameters: parameters)
                configuration(integrationCall)
                integrationCall.call(queue: queue, delay: delay)
            }
        }
        
        return self
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
    
    @discardableResult
    public func nextSuccess<DataProvider, Model, Result>(integrator: Integrator<DataProvider, Model, Result>,
                                                         parametersBuilder: ((ModelType?) -> DataProvider.ParameterType?)? = nil,
                                                         configuration: @escaping (IntegrationCall<Result>) -> () = { _ in }) -> Self {
        let success = doSuccess
        let queue = callQueue
        let delay = callDelay
        
        doSuccess = { result in
            success?(result)
            let parameters = parametersBuilder?(result)
            let next = integrator.prepareCall(parameters: parameters)
            configuration(next)
            next.call(queue: queue, delay: delay)
        }
        
        return self
    }
    
    @discardableResult
    public func forwardSuccess<DataProvider, Model, Result>(integrator: Integrator<DataProvider, Model, Result>,
                                                            configuration: @escaping (IntegrationCall<Result>) -> () = { _ in }) -> Self where DataProvider.ParameterType == ModelType {
        let success = doSuccess
        let queue = callQueue
        let delay = callDelay
        
        doSuccess = { result in
            success?(result)
            let next = integrator.prepareCall(parameters: result)
            configuration(next)
            next.call(queue: queue, delay: delay)
        }
        return self
    }
    
    @discardableResult
    public func nextError<DataProvider, Model, Result>(integrator: Integrator<DataProvider, Model, Result>,
                                                       parametersBuilder: ((Error?) -> DataProvider.ParameterType?)? = nil,
                                                       configuration: @escaping (IntegrationCall<Result>) -> () = { _ in }) -> Self {
        let block = doError
        let queue = callQueue
        let delay = callDelay
        
        doError = { error in
            block?(error)
            let parameters = parametersBuilder?(error)
            let next = integrator.prepareCall(parameters: parameters)
            configuration(next)
            next.call(queue: queue, delay: delay)
        }
        
        return self
    }
    
    @discardableResult
    public func fowardError<DataProvider, Model, Result>(integrator: Integrator<DataProvider, Model, Result>,
                                                         configuration: @escaping (IntegrationCall<Result>) -> () = { _ in }) -> Self where DataProvider.ParameterType == Error {
        let block = doError
        let queue = callQueue
        let delay = callDelay
        
        doError = { error in
            block?(error)
            let next = integrator.prepareCall(parameters: error)
            configuration(next)
            next.call(queue: queue, delay: delay)
        }
        
        return self
    }
    
    @discardableResult
    public func nextCompletion<DataProvider, Model, Result>(integrator: Integrator<DataProvider, Model, Result>,
                                                            parameters: DataProvider.ParameterType? = nil,
                                                            configuration: @escaping (IntegrationCall<Result>) -> () = { _ in }) -> Self {
        let block = doCompletion
        let queue = callQueue
        let delay = callDelay
        
        doCompletion = {
            block?()
            let next = integrator.prepareCall(parameters: parameters)
            configuration(next)
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
    @discardableResult
    public func onProgress(_ handler: ((ModelType?) -> ())?) -> Self {
        doProgress = handler
        return self
    }
    
    @discardableResult
    public func progress<T: ProgressTrackingProtocol>(tracker: T) -> Self where T: AnyObject, T.ModelType == ModelType {
        onProgress { [weak tracker] model in
            tracker?.progressDidUpdate(data: model)
        }
        return self
    }
}

infix operator -->: AdditionPrecedence
infix operator ->>: AdditionPrecedence
infix operator !->: AdditionPrecedence

public func --> <R1, R2>(left: IntegrationCall<R1>, right: IntegrationCall<R2>) -> IntegrationCall<R1> {
    return left.next(state: .completion, integrationCall: right)
}

public func ->> <R1, R2>(left: IntegrationCall<R1>, right: IntegrationCall<R2>) -> IntegrationCall<R1> {
    return left.next(state: .success, integrationCall: right)
}

public func !-> <R1, R2>(left: IntegrationCall<R1>, right: IntegrationCall<R2>) -> IntegrationCall<R1> {
    return left.next(state: .error, integrationCall: right)
}

extension IntegrationCall {
    public func isSameIntegrator<R>(with other: IntegrationCall<R>) -> Bool {
        if let checked = integrator?.isEqual(other.integrator) {
            return checked
        }
        return false
    }
}
