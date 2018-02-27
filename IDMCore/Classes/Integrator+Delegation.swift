//
//  Integrator+Extensions.swift
//  IDMCore
//
//  Created by NGUYEN CHI CONG on 5/10/17.
//
//

import Foundation

extension Integrator {
    public func setLoadingHandler<T: LoadingProtocol>(_ object: T) where T: AnyObject {
        onBeginning { [weak object] in
            object?.beginLoading()
        }
        onCompletion { [weak object] in
            object?.finishLoading()
        }
    }

    public func setErrorHandler<T: ErrorHandlingProtocol>(_ object: T) where T: AnyObject {
        onError { [weak object] err in
            object?.handle(error: err)
        }
    }

    public func setSuccessHandler<T>(_ object: T) where T: DataProcessingProtocol, T: AnyObject, T.ModelType == ResultType {
        onSuccess { [weak object] data in
            object?.process(data: data)
        }
    }

    public func setDelegate<T>(_ object: T) where T: DataProcessingProtocol, T: LoadingProtocol, T: ErrorHandlingProtocol, T: AnyObject, T.ModelType == ResultType {
        setLoadingHandler(object)
        setErrorHandler(object)
        setSuccessHandler(object)
    }
}
