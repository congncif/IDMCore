/**
 Copyright (c) 2016 Nguyen Chi Cong
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

//
//  IntegrationCall+Delegation.swift
//  IDMCore
//
//  Created by NGUYEN CHI CONG on 2/27/18.
//

import Foundation

extension IntegrationCall {
    @discardableResult
    public func loadingHandler<T: LoadingProtocol>(_ handler: T) -> Self where T: AnyObject {
        onBeginning { [weak handler] in
            handler?.beginLoading()
        }
        
        onCompletion { [weak handler] in
            handler?.finishLoading()
        }
        
        return self
    }
    
    @discardableResult
    public func errorHandler<T: ErrorHandlingProtocol>(_ handler: T) -> Self where T: AnyObject {
        onError { [weak handler] err in
            handler?.handle(error: err)
        }
        
        return self
    }
    
    @discardableResult
    public func dataProcessor<T: DataProcessingProtocol>(_ processor: T) -> Self where T: AnyObject, T.ModelType == ModelType {
        onSuccess { [weak processor] model in
            processor?.process(data: model)
        }
        
        return self
    }
    
    @discardableResult
    public func display<T>(on view: T) -> Self where T: AnyObject, T: LoadingProtocol, T: ErrorHandlingProtocol {
        loadingHandler(view).errorHandler(view)
        return self
    }
    
    @discardableResult
    public func delegate<T>(_ delegate: T) -> Self where T: AnyObject, T: LoadingProtocol, T: ErrorHandlingProtocol, T: DataProcessingProtocol, T.ModelType == ModelType {
        loadingHandler(delegate).errorHandler(delegate).dataProcessor(delegate)
        return self
    }
    
    @discardableResult
    public func dataProcessor<T: DataProcessingProtocol>(_ processor: T) -> Self where T.ModelType == ModelType {
        onSuccess(processor.process)
        return self
    }
}
