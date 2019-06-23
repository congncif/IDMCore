//
//  DedicatedErrorHandling.swift
//  IDMCore
//
//  Created by NGUYEN CHI CONG on 3/21/19.
//

import Foundation

public protocol DedicatedErrorHandlingProtocol {
    associatedtype ErrorType
    func handleDedicatedError(_ error: ErrorType)
}

extension ErrorHandlingProtocol where Self: DedicatedErrorHandlingProtocol {
    public func handle(error: Error?) {
        guard let dedicatedError = error as? ErrorType else { return }
        handleDedicatedError(dedicatedError)
    }
}

public struct DedicatedErrorHandler<E>: DedicatedErrorHandlingProtocol, ErrorHandlingProtocol {
    public typealias ErrorType = E
    public typealias Handler = (ErrorType) -> Void

    private var handler: Handler

    public init(errorType: ErrorType.Type, handler: @escaping Handler) {
        self.handler = handler
    }

    public init(handler: @escaping Handler) {
        self.handler = handler
    }

    public func handleDedicatedError(_ error: ErrorType) {
        handler(error)
    }
}
