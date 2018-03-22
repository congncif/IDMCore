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
//  DataProtocol.swift
//  Pods
//
//  Created by NGUYEN CHI CONG on 8/15/16.
//
//

import Foundation

public typealias CancelHandler = () -> Void

public protocol DataProviderProtocol {
    associatedtype ParameterType
    associatedtype DataType

    /// Implement this method for requesting/fetching/getting data from Internet/Database/Storage files, ...
    ///
    /// - Parameters:
    ///   - parameters: conditions of request
    ///   - completion: call completion to forward data to next processing (Integration)
    /// - Returns: a closure to handle cancelling action when the request is cancelled
    @discardableResult
    func request(parameters: ParameterType?, completion: @escaping (Bool, DataType?, Error?) -> Void) -> CancelHandler?
}
