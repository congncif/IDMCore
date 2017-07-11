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

    init?(from data: DataType?)
    func getData<ReturnType>() -> ReturnType?
    
    var invalidDataError: Error? {get}
}

public protocol SelfModelProtocol: ModelProtocol {}

extension SelfModelProtocol {
    public typealias DataType = Self

    public init?(from data: Self?) {
        guard let data = data else {
            return nil
        }
        self = data
    }
}

extension ModelProtocol {
    public func getData<ReturnType>() -> ReturnType? {
        if ReturnType.self == Self.self {
            return self as? ReturnType
        }
        fatalError("Result Type only accept type \(Self.self)")
    }
    
    public var invalidDataError: Error? {
        return nil
    }
}

public struct AutoWrapModel<Type>: ModelProtocol {

    public fileprivate(set) var data: Type?
    public init?(from data: Type?) {
        self.data = data
    }

    public func getData<ReturnType>() -> ReturnType? {
        if ReturnType.self == Type.self {
            return data as? ReturnType
        }
        if ReturnType.self == AutoWrapModel<Type>.self {
            return self as? ReturnType
        }
        fatalError("Result Type only accept type \(Type.self) or \(AutoWrapModel<Type>.self)")
    }
}
