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

    open func request(parameters: Parameter?, completionResult: @escaping (ResultType) -> Void) -> CancelHandler? {
        assertionFailure("\(type(of: self)): Abstract method needs an implementation")
        return nil
    }
}

public typealias AnyResultDataProvider<ParameterType> = AbstractDataProvider<ParameterType, Any>
public typealias AnyAnyDataProvider = AbstractDataProvider<Any, Any>

// -------------------------------------------------------------------------

open class DataProvider<ParameterType, ValueType>: AbstractDataProvider<ParameterType, ValueType> {
    public typealias ValueResult = SimpleResult<ValueType?>
    public typealias ValueFactory = (ParameterType?) -> ValueResult

    private var valueFactory: ValueFactory

    public init(valueFactory: @escaping ValueFactory) {
        self.valueFactory = valueFactory
    }

    open override func request(parameters: ParameterType?, completionResult: @escaping (ValueResult) -> Void) -> CancelHandler? {
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

    private func request(parameters: ParameterType?,
                         completion: @escaping (Bool, ValueType?, Error?) -> Void) -> CancelHandler? {
        switch valueFactory(parameters) {
        case .success(let data):
            completion(true, data, nil)
        case .failure(let error):
            completion(false, nil, error)
        }
        return nil
    }
}

extension DataProvider where ParameterType == Any {
    // flashFactory is a shortcut of valueFactory with no explicit parameters
    public convenience init(flashFactory: @escaping () -> ValueResult) {
        let _valueFactory: ValueFactory = { _ in flashFactory() }
        self.init(valueFactory: _valueFactory)
    }
}

public typealias ValueDataProvider<ValueType> = DataProvider<Any, ValueType>
public typealias AnyValueDataProvider<ParameterType> = DataProvider<ParameterType, Any>
public typealias AnyAnyValueDataProvider = DataProvider<Any, Any>
