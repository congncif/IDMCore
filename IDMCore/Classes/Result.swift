//
//  Result.swift
//  IDMCore
//
//  Created by NGUYEN CHI CONG on 2/24/19.
//

import Foundation

public enum Result<Value> {
    case success(Value?)
    case failure(Error?)
}

extension Result {
    public var value: Value? {
        switch self {
        case .success(let _value):
            return _value
        default:
            return nil
        }
    }
    
    public var error: Error? {
        switch self {
        case .failure(let _error):
            return _error
        default:
            return nil
        }
    }
}
