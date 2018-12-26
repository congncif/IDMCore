//
//  IDMError.swift
//  IDMCore
//
//  Created by FOLY on 12/26/18.
//

import Foundation

public struct IDMError: LocalizedError {
    public static let modelCannotInitialize = IDMError(message: NSLocalizedString("Model cannot initialize", comment: ""))

    public var message: String
    public var failureReason: String?

    public init(message: String, reason: String? = nil) {
        self.message = message
        self.failureReason = reason
    }

    public var errorDescription: String? {
        return self.message
    }
}

public struct IgnoreError: LocalizedError {
    public var errorDescription: String? {
        return NSLocalizedString("Ignore this error", comment: "")
    }
}
