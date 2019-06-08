//
//  Result.swift
//  IDMCore
//
//  Created by NGUYEN CHI CONG on 2/24/19.
//

import Foundation

public typealias SimpleResult<Success> = Swift.Result<Success, Error>

extension Swift.Result {
    public var value: Success? {
        return try? get()
    }

    public var error: Failure? {
        switch self {
        case .failure(let _error):
            return _error
        default:
            break
        }
        return nil
    }
}
