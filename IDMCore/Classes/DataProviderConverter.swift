//
//  DataProviderConverter.swift
//  IDMCore
//
//  Created by FOLY on 12/28/18.
//

import Foundation

open class IntegratingDataProvider<I: IntegratorProtocol>: DataProviderProtocol {
    public private(set) var internalIntegrator: I
    public private(set) var queue: DispatchQueue

    public init(integrator: I, on requestQueue: DispatchQueue = .main) {
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
    public func convertToDataProvider(queue: DispatchQueue = .main) -> IntegratingDataProvider<Self> {
        return IntegratingDataProvider(integrator: self, on: queue)
    }
}
