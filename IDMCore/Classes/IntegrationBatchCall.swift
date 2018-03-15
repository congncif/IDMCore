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
//  IntegrationBatchCall.swift
//  IDMFoundation
//
//  Created by FOLY on 3/13/18.
//

import Foundation

public class IntegrationBatchCall {
    public init() {
//        #if DEBUG
//            print("Created a batch call")
//        #endif
    }
    
    public func chant<M>(calls: [IntegrationCall<M>], completion: (([Result<M>]) -> Void)?) {
        let numberCalls = calls.count
        var results: [Result<M>] = [] {
            didSet {
                if results.count == numberCalls {
                    completion?(results)
                }
            }
        }
        
        let internalCalls = calls
        for call in internalCalls {
            call
                .next(state: .success, nextBlock: { result in
                    if let data = result {
                        results.append(data)
                    }
                })
                .next(state: .error, nextBlock: { error in
                    if let data = error {
                        results.append(data)
                    }
                })
                .call()
        }
    }
    
    public class func chant<M>(calls: [IntegrationCall<M>], completion: (([Result<M>]) -> Void)?) {
        IntegrationBatchCall().chant(calls: calls, completion: completion)
    }
    
    deinit {
//        #if DEBUG
//            print("Batch call is released")
//        #endif
    }
}
