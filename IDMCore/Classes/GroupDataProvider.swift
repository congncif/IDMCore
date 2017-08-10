//
//  GroupDataProvider.swift
//  IDMCore
//
//  Created by NGUYEN CHI CONG on 9/16/16.
//  Copyright © 2016 NGUYEN CHI CONG. All rights reserved.
//

import Foundation

//////////////////////////////////////////////////////////////////////////////////////

infix operator >><<: AdditionPrecedence

public func >><< <A: DataProviderProtocol, B: DataProviderProtocol>(left: A, right: B) -> GroupDataProvider<A, B> {
    return GroupDataProvider(left, right)
}

public func >><< <A: DataProviderProtocol, B: DataProviderProtocol, C: DataProviderProtocol>(left: GroupDataProvider<A, B>, right: C) -> Group3DataProvider<A, B, C> {
    return Group3DataProvider(left, right)
}

public func >><< <A: DataProviderProtocol, B: DataProviderProtocol, C: DataProviderProtocol, D: DataProviderProtocol>(left: Group3DataProvider<A, B, C>, right: D) -> Group4DataProvider<A, B, C, D> {
    return Group4DataProvider(left, right)
}

public func >><< <A: DataProviderProtocol, B: DataProviderProtocol, C: DataProviderProtocol, D: DataProviderProtocol, E: DataProviderProtocol>(left: Group4DataProvider<A, B, C, D>, right: E) -> Group5DataProvider<A, B, C, D, E> {
    return Group5DataProvider(left, right)
}

//////////////////////////////////////////////////////////////////////////////////////

extension DataProviderProtocol {
    func requestSubItem<S: DataProviderProtocol>(sub: S,
                                                 grouptasks: DispatchGroup,
                                                 parameter: S.ParameterType?,
                                                 cancelBlocks: inout [(() -> Void)],
                                                 done: @escaping (Bool, S.DataType?, Error?) -> Void) {

        var resultLocal: S.DataType?
        var successLocal = true
        var errorLocal: Error?

        grouptasks.enter()

        let cancel = sub.request(parameters: parameter, completion: { success, data, error in

            defer {
                done(successLocal, resultLocal, errorLocal)
                grouptasks.leave()
            }

            successLocal = successLocal && success
            if !successLocal {
                errorLocal = errorLocal ?? error
            } else {
                resultLocal = data
            }
        })
        if cancel != nil {
            cancelBlocks.append(cancel!)
        }
    }

    func processSubRequestDone<D>(success: inout Bool, result: inout D?, error: inout Error?, s: Bool, d: D?, e: Error?) {
        success = success && s
        result = d

        if !success {
            error = error ?? e
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////

public class GroupDataProvider<FirstProvider: DataProviderProtocol, SecondProvider: DataProviderProtocol>: DataProviderProtocol {

    public typealias ParameterType = (FirstProvider.ParameterType?, SecondProvider.ParameterType?)
    public typealias DataType = (FirstProvider.DataType?, SecondProvider.DataType?)

    var firstProvider: FirstProvider
    var secondProvider: SecondProvider

    public init(_ firstProvider: FirstProvider, _ secondProvider: SecondProvider) {
        self.firstProvider = firstProvider
        self.secondProvider = secondProvider
    }

    @discardableResult
    public func request(parameters: ParameterType?, completion: @escaping (Bool, DataType?, Error?) -> Void) -> CancelHandler? {

        var cancelBlocks: [(() -> Void)] = []

        var resultsSuccess = true
        var resultsError: Error?

        var result1: FirstProvider.DataType?
        var result2: SecondProvider.DataType?

        let grouptasks: DispatchGroup = DispatchGroup()

        requestSubItem(sub: firstProvider, grouptasks: grouptasks, parameter: parameters?.0, cancelBlocks: &cancelBlocks) { [weak self] s, d, e in
            self?.processSubRequestDone(success: &resultsSuccess, result: &result1, error: &resultsError, s: s, d: d, e: e)
        }
        requestSubItem(sub: secondProvider, grouptasks: grouptasks, parameter: parameters?.1, cancelBlocks: &cancelBlocks) { [weak self] s, d, e in
            self?.processSubRequestDone(success: &resultsSuccess, result: &result2, error: &resultsError, s: s, d: d, e: e)
        }

        grouptasks.notify(queue: DispatchQueue.global(qos: .background)) {
            let results: DataType = (result1, result2)
            DispatchQueue.main.async(execute: {
                completion(resultsSuccess, results, resultsError)
            })
            cancelBlocks.removeAll()
        }

        return {
            for cancel in cancelBlocks {
                cancel()
            }
        }
    }
}

public class Group3DataProvider<A: DataProviderProtocol, B: DataProviderProtocol, C: DataProviderProtocol>: DataProviderProtocol {

    public typealias G2 = GroupDataProvider<A, B>

    public typealias ParameterType = (A.ParameterType?, B.ParameterType?, C.ParameterType?)
    public typealias DataType = (A.DataType?, B.DataType?, C.DataType?)

    var firstProvider: G2
    var secondProvider: C

    public init(_ firstProvider: G2, _ secondProvider: C) {
        self.firstProvider = firstProvider
        self.secondProvider = secondProvider
    }

    @discardableResult
    public func request(parameters: ParameterType?, completion: @escaping (Bool, DataType?, Error?) -> Void) -> CancelHandler? {

        var cancelBlocks: [(() -> Void)] = []

        var resultsSuccess = true
        var resultsError: Error?

        var result1: A.DataType?
        var result2: B.DataType?
        var result3: C.DataType?

        let grouptasks: DispatchGroup = DispatchGroup()

        requestSubItem(sub: firstProvider.firstProvider, grouptasks: grouptasks, parameter: parameters?.0, cancelBlocks: &cancelBlocks) { [weak self] s, d, e in
            self?.processSubRequestDone(success: &resultsSuccess, result: &result1, error: &resultsError, s: s, d: d, e: e)
        }
        requestSubItem(sub: firstProvider.secondProvider, grouptasks: grouptasks, parameter: parameters?.1, cancelBlocks: &cancelBlocks) { [weak self] s, d, e in
            self?.processSubRequestDone(success: &resultsSuccess, result: &result2, error: &resultsError, s: s, d: d, e: e)
        }

        requestSubItem(sub: secondProvider, grouptasks: grouptasks, parameter: parameters?.2, cancelBlocks: &cancelBlocks) { [weak self] s, d, e in
            self?.processSubRequestDone(success: &resultsSuccess, result: &result3, error: &resultsError, s: s, d: d, e: e)
        }

        grouptasks.notify(queue: DispatchQueue.global(qos: .background)) {
            let results: DataType = (result1, result2, result3)
            DispatchQueue.main.async(execute: {
                completion(resultsSuccess, results, resultsError)
            })
            cancelBlocks.removeAll()
        }

        return {
            for cancel in cancelBlocks {
                cancel()
            }
        }
    }
}

public class Group4DataProvider<A: DataProviderProtocol, B: DataProviderProtocol, C: DataProviderProtocol, D: DataProviderProtocol>: DataProviderProtocol {
    public typealias G3 = Group3DataProvider<A, B, C>

    public typealias ParameterType = (A.ParameterType?, B.ParameterType?, C.ParameterType?, D.ParameterType?)
    public typealias DataType = (A.DataType?, B.DataType?, C.DataType?, D.DataType?)

    var firstProvider: G3
    var secondProvider: D

    public init(_ firstProvider: G3, _ secondProvider: D) {
        self.firstProvider = firstProvider
        self.secondProvider = secondProvider
    }

    public func request(parameters: ParameterType?, completion: @escaping (Bool, DataType?, Error?) -> Void) -> CancelHandler? {

        var cancelBlocks: [(() -> Void)] = []

        var resultsSuccess = true
        var resultsError: Error?

        var result1: A.DataType?
        var result2: B.DataType?
        var result3: C.DataType?
        var result4: D.DataType?

        let grouptasks: DispatchGroup = DispatchGroup()

        requestSubItem(sub: firstProvider.firstProvider.firstProvider, grouptasks: grouptasks, parameter: parameters?.0, cancelBlocks: &cancelBlocks) { [weak self] s, d, e in
            self?.processSubRequestDone(success: &resultsSuccess, result: &result1, error: &resultsError, s: s, d: d, e: e)
        }
        requestSubItem(sub: firstProvider.firstProvider.secondProvider, grouptasks: grouptasks, parameter: parameters?.1, cancelBlocks: &cancelBlocks) { [weak self] s, d, e in
            self?.processSubRequestDone(success: &resultsSuccess, result: &result2, error: &resultsError, s: s, d: d, e: e)
        }

        requestSubItem(sub: firstProvider.secondProvider, grouptasks: grouptasks, parameter: parameters?.2, cancelBlocks: &cancelBlocks) { [weak self] s, d, e in
            self?.processSubRequestDone(success: &resultsSuccess, result: &result3, error: &resultsError, s: s, d: d, e: e)
        }

        requestSubItem(sub: secondProvider, grouptasks: grouptasks, parameter: parameters?.3, cancelBlocks: &cancelBlocks) { [weak self] s, d, e in
            self?.processSubRequestDone(success: &resultsSuccess, result: &result4, error: &resultsError, s: s, d: d, e: e)
        }

        grouptasks.notify(queue: DispatchQueue.global(qos: .background)) {
            let results: DataType = (result1, result2, result3, result4)
            DispatchQueue.main.async(execute: {
                completion(resultsSuccess, results, resultsError)
            })
            cancelBlocks.removeAll()
        }

        return {
            for cancel in cancelBlocks {
                cancel()
            }
        }
    }
}

public class Group5DataProvider<A: DataProviderProtocol, B: DataProviderProtocol, C: DataProviderProtocol, D: DataProviderProtocol, E: DataProviderProtocol>: DataProviderProtocol {
    public typealias G4 = Group4DataProvider<A, B, C, D>

    public typealias ParameterType = (A.ParameterType?, B.ParameterType?, C.ParameterType?, D.ParameterType?, E.ParameterType?)
    public typealias DataType = (A.DataType?, B.DataType?, C.DataType?, D.DataType?, E.DataType?)

    var firstProvider: G4
    var secondProvider: E

    public init(_ firstProvider: G4, _ secondProvider: E) {
        self.firstProvider = firstProvider
        self.secondProvider = secondProvider
    }

    public func request(parameters: ParameterType?, completion: @escaping (Bool, DataType?, Error?) -> Void) -> CancelHandler? {

        var cancelBlocks: [(() -> Void)] = []

        var resultsSuccess = true
        var resultsError: Error?

        var result1: A.DataType?
        var result2: B.DataType?
        var result3: C.DataType?
        var result4: D.DataType?
        var result5: E.DataType?

        let grouptasks: DispatchGroup = DispatchGroup()

        requestSubItem(sub: firstProvider.firstProvider.firstProvider.firstProvider, grouptasks: grouptasks, parameter: parameters?.0, cancelBlocks: &cancelBlocks) { [weak self] s, d, e in
            self?.processSubRequestDone(success: &resultsSuccess, result: &result1, error: &resultsError, s: s, d: d, e: e)
        }
        requestSubItem(sub: firstProvider.firstProvider.firstProvider.secondProvider, grouptasks: grouptasks, parameter: parameters?.1, cancelBlocks: &cancelBlocks) { [weak self] s, d, e in
            self?.processSubRequestDone(success: &resultsSuccess, result: &result2, error: &resultsError, s: s, d: d, e: e)
        }

        requestSubItem(sub: firstProvider.firstProvider.secondProvider, grouptasks: grouptasks, parameter: parameters?.2, cancelBlocks: &cancelBlocks) { [weak self] s, d, e in
            self?.processSubRequestDone(success: &resultsSuccess, result: &result3, error: &resultsError, s: s, d: d, e: e)
        }

        requestSubItem(sub: firstProvider.secondProvider, grouptasks: grouptasks, parameter: parameters?.3, cancelBlocks: &cancelBlocks) { [weak self] s, d, e in
            self?.processSubRequestDone(success: &resultsSuccess, result: &result4, error: &resultsError, s: s, d: d, e: e)
        }

        requestSubItem(sub: secondProvider, grouptasks: grouptasks, parameter: parameters?.4, cancelBlocks: &cancelBlocks) { [weak self] s, d, e in
            self?.processSubRequestDone(success: &resultsSuccess, result: &result5, error: &resultsError, s: s, d: d, e: e)
        }

        grouptasks.notify(queue: DispatchQueue.global(qos: .background)) {
            let results: DataType = (result1, result2, result3, result4, result5)
            DispatchQueue.main.async(execute: {
                completion(resultsSuccess, results, resultsError)
            })
            cancelBlocks.removeAll()
        }

        return {
            for cancel in cancelBlocks {
                cancel()
            }
        }
    }
}
