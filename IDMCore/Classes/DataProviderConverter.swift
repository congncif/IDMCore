//
//  DataProviderConverter.swift
//  IDMCore
//
//  Created by FOLY on 12/28/18.
//

import Foundation

extension DataProviderProtocol {
    public func convertToIntegrator<M>(modelType: M.Type,
                                       executingType: IntegrationType = .default) -> MagicalIntegrator<Self, M>
        where M: ModelProtocol, Self.DataType == M.DataType {
        return MagicalIntegrator(dataProvider: self, modelType: M.self, executingType: executingType)
    }

    public func convertToIntegrator(executingType: IntegrationType = .default) -> AmazingIntegrator<Self> {
        return AmazingIntegrator(dataProvider: self, executingType: executingType)
    }

    public var integrator: AmazingIntegrator<Self> {
        return convertToIntegrator()
    }
}

public final class IntegratingDataProvider<I: IntegratorProtocol>: DataProviderProtocol {
    public private(set) var internalIntegrator: I
    public private(set) var queue: IntegrationCallQueue

    public init(integrator: I, on requestQueue: IntegrationCallQueue = .main) {
        internalIntegrator = integrator
        queue = requestQueue
    }

    public typealias GResultType = SimpleResult<I.GResultType?>

    public func request(parameters: I.GParameterType, completionResult: @escaping (GResultType) -> Void) -> CancelHandler? {
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

    private func request(parameters: I.GParameterType,
                         completion: @escaping (Bool, I.GResultType?, Error?) -> Void) -> CancelHandler? {
        internalIntegrator
            .prepareCall(parameters: parameters)
            .onSuccess { data in
                completion(true, data, nil)
            }
            .onError { error in
                completion(false, nil, error)
            }
            .call(queue: queue)

        return { [weak self] in
            guard let self = self else { return }
            self.internalIntegrator.cancel()
        }
    }
}

extension IntegratorProtocol {
    public func convertToDataProvider(queue: IntegrationCallQueue = .main) -> IntegratingDataProvider<Self> {
        return IntegratingDataProvider(integrator: self, on: queue)
    }

    public var dataProvider: IntegratingDataProvider<Self> {
        return convertToDataProvider()
    }
}

open class ConvertDataProvider<P1, P2>: DataProviderProtocol {
    public typealias ParameterType = P1
    public typealias DataType = P2

    private var converter: ((P1) throws -> P2)?
    private var queue: DispatchQueue?

    public convenience init(queue: DispatchQueue? = nil, converter: @escaping ((P1) throws -> P2)) {
        self.init(queue: queue)
        self.converter = converter
    }

    public init(queue: DispatchQueue? = nil) {
        self.queue = queue
    }

    public func request(parameters: ParameterType, completionResult: @escaping (ResultType) -> Void) -> CancelHandler? {
        let block = { [weak self] in
            if let convertFunc = self?.converter {
                do {
                    let outParameter = try convertFunc(parameters)
                    completionResult(.success(outParameter))
                } catch let ex {
                    completionResult(.failure(ex))
                }
            } else {
                do {
                    let outParameter = try self?.convert(parameter: parameters)
                    completionResult(.success(outParameter))
                } catch let ex {
                    completionResult(.failure(ex))
                }
            }
        }

        if let queue = self.queue {
            queue.async(execute: block)
        } else {
            block()
        }
        return nil
    }

    open func convert(parameter: P1) throws -> P2 {
        preconditionFailure("Converter needs an implementation")
    }
}

public final class ForwardDataProvider<P>: ConvertDataProvider<P, P> {
    private let forwarder: (P) throws -> P

    public init(queue: DispatchQueue? = nil, forwarder: @escaping ((P) throws -> P)) {
        self.forwarder = forwarder
        super.init(queue: queue)
    }

    public convenience init(queue: DispatchQueue? = nil, sideEffect: @escaping (P) -> Void) {
        self.init(queue: queue, forwarder: {
            sideEffect($0)
            return $0
        })
    }

    override public func convert(parameter: P) throws -> P {
        return try forwarder(parameter)
    }
}

public final class BridgeDataProvider<P, R: ModelProtocol>: ConvertDataProvider<P, R> where R.DataType == P {
    override public init(queue: DispatchQueue? = nil) {
        super.init(queue: queue)
    }

    override public func convert(parameter: P) throws -> R {
        do {
            let data: R = try R(fromData: parameter)
            return data
        } catch let ex {
            throw ex
        }
    }
}
