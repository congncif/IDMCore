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
}

public protocol IntegratorProtocol: class {
    associatedtype GParameterType
    associatedtype GResultType

    func prepareCall(parameters: GParameterType?) -> IntegrationCall<GResultType>
    func cancel()
}

//////////////////////////////////////////////////////////////////////////////////////
extension IntegrationProtocol where DataProviderType.DataType == ModelType.DataType {
    func finish(success: Bool,
                data: DataProviderType.DataType?,
                error: Error?,
                completion: ((Bool, ResultType?, Error?) -> Void)?) {
        if success {
            DispatchQueue.global(qos: .userInitiated).async {
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
                    newSuccess = false
                    newError = ex
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
        _ = dataProvider.request(parameters: parameters, completionResult: { result in
            var success: Bool
            var data: DataProviderType.DataType?
            var error: Error?

            switch result {
            case .success(let _data):
                success = true
                data = _data
            case .failure(let _error):
                success = false
                error = _error
            }

            self.finish(success: success, data: data, error: error, completion: completion)
        })
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
            completionHandler?()
        }
    }
}
