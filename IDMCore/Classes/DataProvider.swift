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
//  DataProvider.swift
//  IDMCore
//
//  Created by NGUYEN CHI CONG on 9/16/16.
//  Copyright © 2016 NGUYEN CHI CONG. All rights reserved.
//

import Foundation

open class AbstractDataProvider<Parameter, Data>: DataProviderProtocol {
    public typealias ParameterType = Parameter
    public typealias DataType = Data

    public init() {}

    open func request(parameters: Parameter, completionResult: @escaping (ResultType) -> Void) -> CancelHandler? {
        assertionFailure("\(type(of: self)): Abstract method needs an implementation")
        return nil
    }
}

// MARK: - WrapDataProvider

open class WrapDataProvider<Provider, Parameter, Data>: AbstractDataProvider<Parameter, Data> where Provider: DataProviderProtocol, Provider.ParameterType == Parameter, Provider.DataType == Data {
    private let provider: Provider

    public init(provider: Provider) {
        self.provider = provider
    }

    override open func request(parameters: Parameter, completionResult: @escaping (Result<Data?, Error>) -> Void) -> CancelHandler? {
        return provider.request(parameters: parameters, completionResult: completionResult)
    }
}

extension DataProviderProtocol {
    /**
     Create a `AbstractDataProvider` which will useful for type eraser . This helps declare a generic of `DataProviderProtocol`.
     */

    public var abstracted: AbstractDataProvider<ParameterType, DataType> {
        WrapDataProvider(provider: self)
    }
}

// MARK: - AttachableDataProvider

/**
 * Attach a provider with another provider.
 *
 * Only main provider join in integration. The attached provider will be triggered request along with main provider but cannot cancel and cannot handle completion. Useful for Logger, Analytics or some services without further process.
 *
 * `Provider1` is main provider.
 * `Provider2` is attached provider.
 * Both have same input and output types.
 */

open class AttachableDataProvider<Provider1, Provider2, Parameter, Data>: AbstractDataProvider<Parameter, Data>
    where
    Provider1: DataProviderProtocol, Provider1.ParameterType == Parameter, Provider1.DataType == Data,
    Provider2: DataProviderProtocol, Provider2.ParameterType == Parameter, Provider2.DataType == Data {
    private let provider: Provider1
    private let attachedProvider: Provider2

    public init(provider: Provider1, attachedProvider: Provider2) {
        self.provider = provider
        self.attachedProvider = attachedProvider
    }

    override open func request(parameters: Parameter,
                               completionResult: @escaping (Result<Data?, Error>) -> Void) -> CancelHandler? {
        let cancelable = provider.request(parameters: parameters, completionResult: completionResult)
        attachedProvider.request(parameters: parameters, completionResult: { _ in })
        return cancelable
    }
}

extension DataProviderProtocol {
    /**
     Create a data provider which will attach `provider` to this provider.

     - Parameter provider: The provider will be attached.
     - Precondition: `provider` must be same input & output types with `self.
     */

    public func attached<Provider>(provider: Provider) -> AbstractDataProvider<ParameterType, DataType>
        where Provider: DataProviderProtocol, Provider.ParameterType == ParameterType, Provider.DataType == DataType {
        AttachableDataProvider(provider: self, attachedProvider: provider)
    }
}

// MARK: - Merge Data Provider

/**
 * Merge two data providers, this might call completion twice if succeed.
 * Useful for Cache Loader or two services have same data processing.
 */
open class MergeDataProvider<Provider1, Provider2, Parameter, Data>: AbstractDataProvider<Parameter, Data>
    where
    Provider1: DataProviderProtocol, Provider1.ParameterType == Parameter, Provider1.DataType == Data,
    Provider2: DataProviderProtocol, Provider2.ParameterType == Parameter, Provider2.DataType == Data {
    private let provider: Provider1
    private let otherProvider: Provider2
    private let completionCondition: ((Data?) -> Bool)?

    /**
     Create a data provider which will merge the first provider with another provider.

     - Parameter provider: The first provider.
     - Parameter otherProvider: The provider which will be merged.
     - Parameter constraintTheFirstCompletionBy: The condtion to the first provider completed. Return `false` if the first provider won't complete if its data is invalid by the condition.
     - Precondition: Both providers have same input and output types.
     */

    public init(provider: Provider1,
                otherProvider: Provider2,
                constraintTheFirstCompletionBy completionCondition: ((Data?) -> Bool)? = nil) {
        self.provider = provider
        self.otherProvider = otherProvider
        self.completionCondition = completionCondition
    }

    override open func request(parameters: Parameter,
                               completionResult: @escaping (Result<Data?, Error>) -> Void) -> CancelHandler? {
        if let condition = completionCondition {
            let cancelable1 = provider.request(parameters: parameters, completionResult: { result in
                switch result {
                case let .success(data):
                    if condition(data) {
                        completionResult(.success(data))
                    } else {
                        // Skip completion
                    }
                case let .failure(error):
                    completionResult(.failure(error))
                }
            })
            let cancelable2 = otherProvider.request(parameters: parameters, completionResult: completionResult)

            return {
                cancelable1?()
                cancelable2?()
            }
        } else {
            let cancelable1 = provider.request(parameters: parameters, completionResult: completionResult)
            let cancelable2 = otherProvider.request(parameters: parameters, completionResult: completionResult)

            return {
                cancelable1?()
                cancelable2?()
            }
        }
    }
}

extension DataProviderProtocol {
    /**
     Create a merged data provider.

     - Parameter provider: The provider will be merged.
     - Parameter completionCondition: The condition for `self` completionResult. `self` won't complete if result data is invalid by the condition.
     - Precondition: `provider` must be same input & output types with `self`.
     */

    public func merged<Provider>(provider: Provider,
                                 completionCondition: ((DataType?) -> Bool)? = nil) -> AbstractDataProvider<ParameterType, DataType>
        where Provider: DataProviderProtocol, Provider.ParameterType == ParameterType, Provider.DataType == DataType {
        MergeDataProvider(provider: self,
                          otherProvider: provider,
                          constraintTheFirstCompletionBy: completionCondition)
    }
}

// MARK: - Quick Data Provider

/**
 * `DataProvider` enables to quick initialize from a value closure.
 */

open class ValueDataProvider<ParameterType, ValueType>: AbstractDataProvider<ParameterType, ValueType> {
    public typealias ValueResult = SimpleResult<ValueType?>
    public typealias ValueFactory = (ParameterType?) -> ValueResult

    private var valueFactory: ValueFactory

    /**
     Initialize a data provider.

     - Parameter valueFactory: The closure which will be performed to return value from a parameter when the provider call request.
     */

    public init(valueFactory: @escaping ValueFactory) {
        self.valueFactory = valueFactory
    }

    override open func request(parameters: ParameterType, completionResult: @escaping (ValueResult) -> Void) -> CancelHandler? {
        return request(parameters: parameters) { success, data, error in
            if success {
                completionResult(.success(data))
            } else if let error = error {
                completionResult(.failure(error))
            } else {
                completionResult(.failure(UnknownError.default))
            }
        }
    }

    private func request(parameters: ParameterType,
                         completion: @escaping (Bool, ValueType?, Error?) -> Void) -> CancelHandler? {
        switch valueFactory(parameters) {
        case let .success(data):
            completion(true, data, nil)
        case let .failure(error):
            completion(false, nil, error)
        }
        return nil
    }
}

extension ValueDataProvider where ParameterType == Void {
    // flashFactory is a shortcut of valueFactory with no explicit parameters
    public convenience init(flashFactory: @escaping () -> ValueResult) {
        let _valueFactory: ValueFactory = { _ in flashFactory() }
        self.init(valueFactory: _valueFactory)
    }
}

// Some pre-defined providers

public typealias AnyResultDataProvider<ParameterType> = AbstractDataProvider<ParameterType, Any>

open class AnyDataProvider: AnyResultDataProvider<Void> {
    override open func request(parameters: Void, completionResult: @escaping (AbstractDataProvider<Void, Any>.ResultType) -> Void) -> CancelHandler? {
        request(completionResult: completionResult)
    }

    open func request(completionResult: @escaping (AbstractDataProvider<Void, Any>.ResultType) -> Void) -> CancelHandler? {
        assertionFailure("\(type(of: self)): Abstract method needs an implementation")
        return nil
    }
}

public typealias AnyResultValueDataProvider<ParameterType> = ValueDataProvider<ParameterType, Any>
