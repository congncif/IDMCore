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

    private var handler: ((ErrorType) -> Void)?

    public init(errorType: ErrorType.Type, handler: ((ErrorType) -> Void)? = nil) {
        self.handler = handler
    }

    public init(handler: ((ErrorType) -> Void)? = nil) {
        self.handler = handler
    }

    public func handleDedicatedError(_ error: ErrorType) {
        handler?(error)
    }
}
