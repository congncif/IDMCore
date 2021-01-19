//
//  BlockDataProvider.swift
//  IDMCore
//
//  Created by FOLY on 1/4/19.
//

import Foundation

/** BlockDataProvider is a synchronous result data provider which created to be compatible to IDM data flow. */

public class BlockDataProvider<P, D>: DataProviderProtocol {
    public typealias ParameterType = P
    public typealias DataType = D

    public typealias RequestFunction = (P) throws -> D

    fileprivate var work: RequestFunction
    private var queue: DispatchQueue?

    public init(queue: DispatchQueue? = nil, work: @escaping RequestFunction) {
        self.queue = queue
        self.work = work
    }

    public func request(parameters: ParameterType, completionResult: @escaping (ResultType) -> Void) -> CancelHandler? {
        let block = { [weak self] in
            do {
                let data = try self?.work(parameters)
                completionResult(.success(data))
            } catch let ex {
                completionResult(.failure(ex))
            }
        }

        if let queue = self.queue {
            queue.async(execute: block)
        } else {
            block()
        }

        return nil
    }
}

public final class BlockIntegrator<P, D>: AmazingIntegrator<BlockDataProvider<P, D>> {
    public init(queue: DispatchQueue? = nil, work: @escaping BlockDataProvider<P, D>.RequestFunction) {
        let provider = BlockDataProvider(queue: queue, work: work)
        super.init(dataProvider: provider, executingType: .only)
    }
}

// MARK: - Quick Data Provider

/**
 * `DataProvider` enables to quick initialize from a value closure.
 */

public final class ValueDataProvider<ParameterType, ValueType>: AbstractDataProvider<ParameterType, ValueType> {
    public typealias ValueFactory = (ParameterType) throws -> ValueType

    private var valueFactory: ValueFactory
    private var queue: DispatchQueue?

    /**
     Initialize a data provider.

     - Parameter valueFactory: The closure which will be performed to return value from a parameter when the provider call request.
     */

    public init(queue: DispatchQueue? = nil, valueFactory: @escaping ValueFactory) {
        self.queue = queue
        self.valueFactory = valueFactory
    }

    override public func request(parameters: ParameterType, completionResult: @escaping (ResultType) -> Void) -> CancelHandler? {
        let block = { [weak self] in
            do {
                let value = try self?.valueFactory(parameters)
                completionResult(.success(value))
            } catch {
                completionResult(.failure(error))
            }
        }

        if let queue = self.queue {
            queue.async(execute: block)
        } else {
            block()
        }

        return nil
    }
}

extension ValueDataProvider where ParameterType == Void {
    // flashFactory is a shortcut of valueFactory with no explicit parameters
    public convenience init(flashFactory: @escaping () -> ValueType) {
        let _valueFactory: ValueFactory = { _ in flashFactory() }
        self.init(valueFactory: _valueFactory)
    }
}
