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
//  DataProvider.swift
//  IDMCore
//
//  Created by NGUYEN CHI CONG on 9/16/16.
//  Copyright © 2016 NGUYEN CHI CONG. All rights reserved.
//

import Foundation

infix operator >>>>: AdditionPrecedence

extension DataProviderProtocol {
    public static func >>>> <SecondProvider: DataProviderProtocol>(left: Self, right: SecondProvider) -> SequenceDataProvider<Self, SecondProvider> {
        return SequenceDataProvider(left, right)
    }
}

open class DataProvider<ParameterType, DataType>: DataProviderProtocol {
    @discardableResult
    open func request(parameters _: ParameterType?, completion _: @escaping (Bool, DataType?, Error?) -> Void) -> CancelHandler? {
        fatalError("Please override \(#function) to get data")
    }
}

public class SequenceDataProvider<FirstProvider: DataProviderProtocol, SecondProvider: DataProviderProtocol>: DataProviderProtocol where FirstProvider.DataType == SecondProvider.ParameterType {

    public typealias ParameterType = FirstProvider.ParameterType
    public typealias DataType = SecondProvider.DataType

    fileprivate var firstProvider: FirstProvider
    fileprivate var secondProvider: SecondProvider

    public init(_ firstProvider: FirstProvider, _ secondProvider: SecondProvider) {
        self.firstProvider = firstProvider
        self.secondProvider = secondProvider
    }

    @discardableResult
    public func request(parameters: FirstProvider.ParameterType?, completion: @escaping (Bool, SecondProvider.DataType?, Error?) -> Void) -> CancelHandler? {

        var cancelBlock: (() -> Void)?

        let param1: FirstProvider.ParameterType? = parameters
        var param2: SecondProvider.ParameterType?
        var results: SecondProvider.DataType?

        var resultsSuccess = true
        var resultsError: Error?

        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)

        DispatchQueue.global(qos: .background).async(execute: { [weak self] in

            defer {
                DispatchQueue.main.async(execute: {
                    cancelBlock = nil
                    completion(resultsSuccess, results, resultsError)
                })
            }

            let cancel = self?.firstProvider.request(parameters: param1, completion: { success, data, error in
                param2 = data
                resultsSuccess = success
                resultsError = error
                semaphore.signal()
            })

            cancelBlock = cancel
            _ = semaphore.wait(timeout: .distantFuture)

            if !resultsSuccess {
                return
            }

            let cancel2 = self?.secondProvider.request(parameters: param2, completion: { success, data, error in
                results = data
                resultsSuccess = success
                resultsError = error
                semaphore.signal()
            })

            cancelBlock = cancel2
            _ = semaphore.wait(timeout: .distantFuture)

            if !resultsSuccess {
                return
            }
        })

        return cancelBlock
    }
}
