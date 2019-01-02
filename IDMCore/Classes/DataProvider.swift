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

extension DataProviderProtocol {
    public func convertToIntegrator<M>(modelType: M.Type,
                                       executingType: IntegrationType = .default) -> MagicalIntegrator<Self, M>
        where M: ModelProtocol, Self.DataType == M.DataType {
        return MagicalIntegrator(dataProvider: self, modelType: M.self, executingType: executingType)
    }

    public func convertToIntegrator(executingType: IntegrationType = .default) -> AmazingIntegrator<Self> {
        return AmazingIntegrator(dataProvider: self, executingType: executingType)
    }

    public var integrator: AmazingIntegrator<Self> {
        return convertToIntegrator()
    }
}

open class AbstractDataProvider<Parameter, Data>: NSObject, DataProviderProtocol {
    public override init() {
        super.init()
    }

    open func request(parameters: Parameter?,
                      completion: @escaping (Bool, Data?, Error?) -> Void) -> CancelHandler? {
        assertionFailure("\(type(of: self)): Abstract method needs an implementation")
        return nil
    }
}

/*
open class ClosureDataProvider: AbstractDataProvider<Any, Any> {
    public typealias DataProviderFunction = ((Bool, Any?, Error?) -> Void)

    private var function: (Any?, DataProviderFunction) -> Void

    public init(function: @escaping (Any?, DataProviderFunction) -> Void) {
        self.function = function
    }

    open override func request(parameters: Any?,
                               completion: @escaping (Bool, Any?, Error?) -> Void) -> CancelHandler? {
        function(parameters, completion)
        return nil
    }
}

public protocol IDMConvertable {
    var toIDM: ClosureDataProvider { get }
}

extension IDMConvertable {
    public var toIDM: ClosureDataProvider {
        return ClosureDataProvider { _, completion in
            completion(true, self, nil)
        }
    }
}

extension NSObject: IDMConvertable {}

extension String: IDMConvertable {}

extension Int: IDMConvertable {}
extension Int8: IDMConvertable {}
extension Int16: IDMConvertable {}
extension Int32: IDMConvertable {}
extension Int64: IDMConvertable {}

extension UInt: IDMConvertable {}
extension UInt8: IDMConvertable {}
extension UInt16: IDMConvertable {}
extension UInt32: IDMConvertable {}
extension UInt64: IDMConvertable {}

extension Double: IDMConvertable {}

extension Float: IDMConvertable {}
extension Float80: IDMConvertable {}
*/
