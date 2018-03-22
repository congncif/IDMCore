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
//  Integrator+Extensions.swift
//  IDMCore
//
//  Created by NGUYEN CHI CONG on 5/10/17.
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

    public func setPresenter<T>(_ object: T) where T: AnyObject, T: LoadingProtocol, T: ErrorHandlingProtocol {
        setLoadingHandler(object)
        setErrorHandler(object)
    }

    public func setDelegate<T>(_ object: T) where T: DataProcessingProtocol, T: LoadingProtocol, T: ErrorHandlingProtocol, T: AnyObject, T.ModelType == ResultType {
        setLoadingHandler(object)
        setErrorHandler(object)
        setSuccessHandler(object)
    }
}
