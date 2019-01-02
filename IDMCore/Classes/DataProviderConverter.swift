//
//  DataProviderConverter.swift
//  IDMCore
//
//  Created by FOLY on 12/28/18.
//

import Foundation

open class IntegratingDataProvider<I: IntegratorProtocol>: DataProviderProtocol {
    public private(set) var internalIntegrator: I
    public private(set) var queue: IntegrationCallQueue

    public init(integrator: I, on requestQueue: IntegrationCallQueue = .main) {
        internalIntegrator = integrator
        queue = requestQueue
    }

    public func request(parameters: I.GParameterType?,
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

open class ConvertDataProvider<P1, P2>: NSObject, DataProviderProtocol {
    private var converter: ((P1?) throws -> P2?)?

    public convenience init(converter: ((P1?) throws -> P2?)?) {
        self.init()
        self.converter = converter
    }

    public override init() {
        super.init()
    }

    open func request(parameters: P1?,
                      completion: @escaping (Bool, P2?, Error?) -> Void) -> CancelHandler? {
        if let convertFunc = self.converter {
            do {
                let outParameter = try convertFunc(parameters)
                completion(true, outParameter, nil)
            } catch let ex {
                completion(false, nil, ex)
            }
        } else {
            do {
                let outParameter = try convert(parameter: parameters)
                completion(true, outParameter, nil)
            } catch let ex {
                completion(false, nil, ex)
            }
        }

        return nil
    }

    open func convert(parameter: P1?) throws -> P2? {
        assertionFailure("Converter needs an implementation")
        return nil
    }
}

open class ForwardDataProvider<P>: ConvertDataProvider<P, P> {
    private var forwarder: ((P?) throws -> P?)?

    public convenience init(forwarder: ((P?) throws -> P?)?) {
        self.init()
        self.forwarder = forwarder
    }

    public override init() {
        super.init()
    }

    open override func convert(parameter: P?) throws -> P? {
        if let forwardFunc = forwarder {
            return try forwardFunc(parameter)
        } else {
            return parameter
        }
    }
}

open class BridgeDataProvider<R: ModelProtocol>: ConvertDataProvider<Any, R> where R.DataType == Any {
    public override init() {
        super.init()
    }

    open override func convert(parameter: Any?) throws -> R? {
        do {
            let data: R? = try R(fromData: parameter)
            return data
        } catch let ex {
            throw ex
        }
    }
}
