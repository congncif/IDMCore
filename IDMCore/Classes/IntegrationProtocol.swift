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
//  IntegrationProtocol.swift
//  IDMCore
//
//  Created by NGUYEN CHI CONG on 8/15/16.
//  Copyright © 2016 NGUYEN CHI CONG. All rights reserved.
//

import Foundation

public protocol IntegrationProtocol: IntegratorProtocol where Self.ParameterType == GParameterType, Self.ResultType == GResultType {
    associatedtype DataProviderType: DataProviderProtocol
    associatedtype ModelType: ModelProtocol
    associatedtype ResultType
    
    typealias ParameterType = DataProviderType.ParameterType
    
    var dataProvider: DataProviderType { get }
    
    func execute(parameters: ParameterType?,
                 completion: ((Bool, ResultType?, Error?) -> Void)?)
    func execute(parameters: ParameterType?,
                 loadingHandler: (() -> Void)?,
                 successHandler: ((ResultType?) -> Void)?,
                 failureHandler: ((Error?) -> Void)?,
                 completionHandler: (() -> Void)?)
    var noValueError: Error? { get }
}

extension IntegrationProtocol {
    public var noValueError: Error? {
        return nil
    }
}

public protocol IntegratorProtocol: class {
    associatedtype GParameterType
    associatedtype GResultType
    
    func prepareCall(parameters: GParameterType?) -> IntegrationCall<GResultType>
    func cancel()
}

//////////////////////////////////////////////////////////////////////////////////////
public extension IntegrationProtocol where DataProviderType.DataType == ModelType.DataType {
    func finish(success: Bool,
                data: DataProviderType.DataType?,
                error: Error?,
                completion: ((Bool, ResultType?, Error?) -> Void)?) {
        let noValueError = self.noValueError
        
        if success {
            DispatchQueue.global(qos: .userInteractive).async {
                var newError = error
                var newSuccess = success
                var results: ResultType?
                do {
                    let model = try ModelType(fromData: data)
                    if let err = model.invalidDataError {
                        newSuccess = false
                        newError = err
                    } else {
                        let resultData: ResultType = try model.getData()
                        results = resultData
                    }
                    
                } catch let ex {
                    if let err = noValueError { // custom noValue error
                        newSuccess = false
                        newError = err
                    } else {
                        newSuccess = false
                        newError = ex
                    }
                    
                    // Ignore noValue error, accept any results includes nil
                    if let _ = newError as? IgnoreError {
                        newSuccess = true
                        newError = nil
                    }
                }
                
                DispatchQueue.main.async {
                    completion?(newSuccess, results, newError)
                }
            }
        } else {
            DispatchQueue.main.async {
                completion?(success, nil, error)
            }
        }
    }
    
    public func execute(parameters: ParameterType? = nil,
                        completion: ((Bool, ResultType?, Error?) -> Void)? = nil) {
        _ = dataProvider.request(parameters: parameters) { success, data, error in
            self.finish(success: success, data: data, error: error, completion: completion)
        }
    }
    
    public func execute(parameters: ParameterType? = nil,
                        loadingHandler: (() -> Void)?,
                        successHandler: ((ResultType?) -> Void)?,
                        failureHandler: ((Error?) -> Void)? = nil,
                        completionHandler: (() -> Void)?) {
        DispatchQueue.main.async {
            loadingHandler?()
        }
        execute(parameters: parameters) { success, model, error in
            if success {
                successHandler?(model)
            } else {
                failureHandler?(error)
            }
            defer {
                completionHandler?()
            }
        }
    }
    
    public func execute<DataBindingType: DataProcessingProtocol>(parameters: ParameterType? = nil,
                                                                 loadingPresenter: LoadingProtocol? = nil,
                                                                 errorAlertPresenter: ErrorHandlingProtocol? = nil,
                                                                 dataBinding: DataBindingType?)
        where DataBindingType.ModelType == ResultType {
        execute(parameters: parameters,
                loadingHandler: {
                    loadingPresenter?.beginLoading()
                },
                successHandler: { data in
                    dataBinding?.process(data: data)
                },
                failureHandler: { error in
                    errorAlertPresenter?.handle(error: error)
                },
                completionHandler: {
                    loadingPresenter?.finishLoading()
        })
    }
    
    public func execute<DataBindingType: DataProcessingProtocol>(parameters: ParameterType? = nil,
                                                                 delegate: DataBindingType?)
        where DataBindingType: LoadingProtocol,
        DataBindingType: ErrorHandlingProtocol,
        DataBindingType.ModelType == ResultType {
        execute(parameters: parameters, loadingPresenter: delegate, errorAlertPresenter: delegate, dataBinding: delegate)
    }
    
    public func execute(parameters: ParameterType? = nil,
                        loadingPresenter: LoadingProtocol? = nil,
                        errorAlertPresenter: ErrorHandlingProtocol? = nil,
                        successHandler: ((ResultType?) -> Void)?) {
        execute(parameters: parameters,
                loadingHandler: {
                    loadingPresenter?.beginLoading()
                },
                successHandler: { data in
                    successHandler?(data)
                },
                failureHandler: { error in
                    errorAlertPresenter?.handle(error: error)
                },
                completionHandler: {
                    loadingPresenter?.finishLoading()
        })
    }
}
