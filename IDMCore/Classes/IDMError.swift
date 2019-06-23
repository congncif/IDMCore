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
    private init() {}
    public static let `default` = IgnoreError()

    public var errorDescription: String? {
        return NSLocalizedString("Ignore this error", comment: "")
    }
}

public struct UnknownError: LocalizedError {
    private init() {}
    public static let `default` = UnknownError()

    public var errorDescription: String? {
        return NSLocalizedString("Unknown error", comment: "Error null")
    }
}

public struct NoDataError: LocalizedError {
    private init() {}
    public static let `default` = NoDataError()

    public var errorDescription: String? {
        return NSLocalizedString("No data available", comment: "")
    }
}

public struct InterruptedError: LocalizedError {
    private init() {}
    public static let `default` = InterruptedError()

    public var errorDescription: String? {
        return NSLocalizedString("The integration is interrupted", comment: "")
    }
}
