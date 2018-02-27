//
//  IntegrationCall+Delegation.swift
//  IDMCore
//
//  Created by NGUYEN CHI CONG on 2/27/18.
//

import Foundation

extension IntegrationCall {
    @discardableResult
    public func loading<T: LoadingProtocol>(monitor: T) -> Self where T: AnyObject {
        onBeginning { [weak monitor] in
            monitor?.beginLoading()
        }
        
        onCompletion { [weak monitor] in
            monitor?.finishLoading()
        }
        
        return self
    }
    
    @discardableResult
    public func error<T: ErrorHandlingProtocol>(handler: T) -> Self where T: AnyObject {
        onError { [weak handler] err in
            handler?.handle(error: err)
        }
        
        return self
    }
    
    @discardableResult
    public func data<T: DataProcessingProtocol>(processor: T) -> Self where T: AnyObject, T.ModelType == ModelType {
        onSuccess { [weak processor] model in
            processor?.process(data: model)
        }
        
        return self
    }
}
