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
//  ModelProtocol.swift
//  IDMCore
//
//  Created by NGUYEN CHI CONG on 8/15/16.
//  Copyright © 2016 NGUYEN CHI CONG. All rights reserved.
//

import Foundation

public protocol ModelProtocol {
    associatedtype DataType
    
    init(fromData data: DataType?) throws
    func getData<ReturnType>() throws -> ReturnType
    
    var invalidDataError: Error? { get }
}

public protocol SelfModelProtocol: ModelProtocol {}

extension SelfModelProtocol {
    public init(fromData data: Self?) throws {
        guard let data = data else {
            throw IDMError.modelCannotInitialize
        }
        self = data
    }
}

extension ModelProtocol {
    public func getData<ReturnType>() throws -> ReturnType {
        if ReturnType.self == Self.self {
            if let result = self as? ReturnType {
                return result
            }
        }
        throw IDMError(message: "*** Cannot getData of type \(Self.self) ***")
    }
    
    public var invalidDataError: Error? {
        return nil
    }
}

public struct AutoWrapModel<Type>: ModelProtocol {
    public fileprivate(set) var data: Type?
    public init(fromData data: Type?) throws {
        self.data = data
    }
    
    public func getData<ReturnType>() throws -> ReturnType {
        if ReturnType.self == Type.self {
            if let result = data as? ReturnType {
                return result
            }
        }
        if ReturnType.self == AutoWrapModel<Type>.self {
            if let result = self as? ReturnType {
                return result
            }
        }
        throw IDMError(message: "*** Cannot getData of type \(Type.self) or \(AutoWrapModel<Type>.self) ***")
    }
}
