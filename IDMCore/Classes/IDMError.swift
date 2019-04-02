//
//  IDMError.swift
//  IDMCore
//
//  Created by FOLY on 12/26/18.
//

import Foundation

public struct ParsingError: LocalizedError {
    public var message: String
    public var failureReason: String?

    public init(message: String, reason: String? = nil) {
        self.message = message
        self.failureReason = reason
    }

    public var errorDescription: String? {
        return NSLocalizedString(self.message, comment: "")
    }
}

public struct IgnoreError: LocalizedError {
    public static let `default` = IgnoreError()
    
    public var errorDescription: String? {
        return NSLocalizedString("Ignore this error", comment: "")
    }
}
