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
    public static func >>>> <SecondProvider: DataProviderProtocol> (left: Self, right: SecondProvider) -> SequenceDataProvider<Self, SecondProvider> where Self.DataType == SecondProvider.ParameterType {
        return SequenceDataProvider( left, right)
    }
}

open class DataProvider<ParameterType, DataType> : DataProviderProtocol {
    @discardableResult
    open func request(parameters: ParameterType?, completion: @escaping  (Bool, DataType?, Error?) -> Void) -> CancelHandler? {
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
        
        var cancelBlock: (() -> ())?
        
        let param1: FirstProvider.ParameterType? = parameters
        var param2: SecondProvider.ParameterType? = nil
        var results: SecondProvider.DataType?
        
        var resultsSuccess = true
        var resultsError: Error? = nil
        
         let semaphore : DispatchSemaphore = DispatchSemaphore(value: 0)
        
        DispatchQueue.global(qos: .background).async(execute: { [unowned self] in
            defer{
                DispatchQueue.main.async(execute: {
                    cancelBlock = nil
                    completion(resultsSuccess, results, resultsError)
                })
            }
            
            let cancel = self.firstProvider.request(parameters: param1, completion: { (success, data, error) in
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

            let cancel2 = self.secondProvider.request(parameters: param2, completion: { (success, data, error) in
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


