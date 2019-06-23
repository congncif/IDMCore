//
//  SequenceDataProvider.swift
//  IDMCore
//
//  Created by FOLY on 12/28/18.
//

import Foundation

infix operator >>>>: AdditionPrecedence

extension DataProviderProtocol {
    public static func >>>> <SecondProvider: DataProviderProtocol>(left: Self, right: SecondProvider) -> SequenceDataProvider<Self, SecondProvider> {
        return SequenceDataProvider(left, right)
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

    public func request(parameters: ParameterType?, completionResult: @escaping (ResultType) -> Void) -> CancelHandler? {
        return request(parameters: parameters) { success, data, error in
            var result: ResultType
            if success {
                result = .success(data)
            } else if let error = error {
                result = .failure(error)
            } else {
                result = .failure(UnknownError.default)
            }
            completionResult(result)
        }
    }

    @discardableResult
    private func request(parameters: FirstProvider.ParameterType?, completion: @escaping (Bool, SecondProvider.DataType?, Error?) -> Void) -> CancelHandler? {
        var cancelBlock: (() -> Void)?

        let param1: FirstProvider.ParameterType? = parameters
        var param2: SecondProvider.ParameterType?
        var results: SecondProvider.DataType?

        var resultsSuccess = true
        var resultsError: Error?

        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            defer {
                DispatchQueue.main.async {
                    cancelBlock = nil
                    completion(resultsSuccess, results, resultsError)
                }
            }

            let cancel = self?.firstProvider.request(parameters: param1, completionResult: { result in
                switch result {
                case .success(let data):
                    resultsSuccess = true
                    param2 = data

                case .failure(let error):
                    resultsSuccess = false
                    resultsError = error
                }

                semaphore.signal()
            })

            cancelBlock = cancel
            _ = semaphore.wait(timeout: .distantFuture)

            if !resultsSuccess {
                return
            }

            let cancel2 = self?.secondProvider.request(parameters: param2, completionResult: { result in
                switch result {
                case .success(let data):
                    resultsSuccess = true
                    results = data
                case .failure(let error):
                    resultsSuccess = false
                    resultsError = error
                }
                semaphore.signal()
            })

            cancelBlock = cancel2
            _ = semaphore.wait(timeout: .distantFuture)

            if !resultsSuccess {
                return
            }
        }

        return cancelBlock
    }
}
