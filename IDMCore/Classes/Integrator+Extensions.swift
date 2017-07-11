//
//  Integrator+Extensions.swift
//  IDMCore
//
//  Created by NGUYEN CHI CONG on 5/10/17.
//
//

import Foundation

public protocol SuccessHandlerProtocol {
    associatedtype T
    func handleSuccess<T>(data: T?)
}

extension Integrator {
    public func setLoadingHandler<T: LoadingHandlerProtocol>(_ object: T) where T: AnyObject {
        onBeginning { [weak object] in
            object?.presentLoadingView()
        }
        onCompletion { [weak object] in
            object?.dismissLoadingView()
        }
    }

    public func setErrorHandler<T: ErrorHandlerProtocol>(_ object: T) where T: AnyObject {
        onError { [weak object] err in
            object?.presentErrorAlert(error: err)
        }
    }

    public func setSuccessHandler<T>(_ object: T) where T: SuccessHandlerProtocol, T: AnyObject {
        onSuccess { [weak object] data in
            object?.handleSuccess(data: data)
        }
    }

    public func setDelegate<T>(_ object: T) where T: SuccessHandlerProtocol, T: LoadingHandlerProtocol, T: ErrorHandlerProtocol, T: AnyObject {
        setLoadingHandler(object)
        setErrorHandler(object)
        setSuccessHandler(object)
    }
}
