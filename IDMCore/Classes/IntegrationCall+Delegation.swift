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
    // mark: - Loading
    
    public func loadingHandler(_ handler: LoadingProtocol) -> Self {
        _ = onBeginning(handler.beginLoading)
        _ = onCompletion(handler.finishLoading)
        return self
    }
    
    public func loadingHandler<H>(_ handler: H?) -> Self where H: LoadingProtocol, H: AnyObject {
        _ = onBeginning { [weak handler] in
            handler?.beginLoading()
        }
        
        _ = onCompletion { [weak handler] in
            handler?.finishLoading()
        }
        
        return self
    }
    
    // mark: - Error Handling
    
    public func errorHandler<H>(_ handler: H?) -> Self where H: ErrorHandlingProtocol, H: AnyObject {
        _ = onError { [weak handler] err in
            handler?.handle(error: err)
        }
        
        return self
    }
    
    public func errorHandler(_ handler: ErrorHandlingProtocol) -> Self {
        _ = onError(handler.handle)
        return self
    }
    
    // mark: - Data Handler
    
    public func dataProcessor<T: DataProcessingProtocol>(_ processor: T) -> Self
        where T: AnyObject, T.ModelType == ModelType {
        _ = onSuccess { [weak processor] model in
            processor?.process(data: model)
        }
        
        return self
    }
    
    public func dataProcessor<T: DataProcessingProtocol>(_ processor: T) -> Self
        where T.ModelType == ModelType {
        _ = onSuccess(processor.process)
        return self
    }
}

extension IntegrationCall where ModelType: DelayingCompletionProtocol {
    public func progressTracker<T: ProgressTrackingProtocol>(_ tracker: T) -> Self
        where T: AnyObject, T.ModelType == ModelType {
        _ = onProgress { [weak tracker] model in
            tracker?.progressDidUpdate(data: model)
        }
        return self
    }
    
    public func progressTracker<T: ProgressTrackingProtocol>(_ tracker: T) -> Self
        where T.ModelType == ModelType {
        _ = onProgress(tracker.progressDidUpdate)
        return self
    }
}

extension IntegrationCall where ModelType: ProgressModelProtocol {
    public func progressTracker<T>(_ tracker: T?) -> Self where T: ProgressLoadingProtocol, T: AnyObject {
        _ = onBeginning { [weak tracker] in
            tracker?.beginProgressLoading()
        }
        
        _ = onCompletion { [weak tracker] in
            tracker?.finishProgressLoading()
        }
        
        _ = onProgress { [weak tracker] model in
            tracker?.loadingDidUpdateProgress(model?.progress)
        }
        return self
    }
    
    public func progressTracker(_ tracker: ProgressLoadingProtocol) -> Self {
        _ = onBeginning(tracker.beginProgressLoading)
        _ = onCompletion(tracker.finishProgressLoading)
        _ = onProgress { tracker.loadingDidUpdateProgress($0?.progress) }
        return self
    }
}
