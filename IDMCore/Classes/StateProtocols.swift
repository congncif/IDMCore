//
//  StateProtocols.swift
//  IDMCore
//
//  Created by FOLY on 12/26/18.
//

import Foundation

public protocol LoadingProtocol {
    func beginLoading()
    func finishLoading()
}

public protocol ProgressLoadingProtocol {
    func beginProgressLoading()
    func loadingDidUpdateProgress(_ progress: Progress?)
    func finishProgressLoading()
}

public protocol ErrorHandlingProtocol {
    func handle(error: Error?)
}

public protocol DataProcessingProtocol {
    associatedtype ModelType
    func process(data: ModelType?)
}

public protocol ProgressTrackingProtocol {
    associatedtype ModelType
    func progressDidUpdate(data: ModelType?)
}

public protocol DelayingCompletionProtocol {
    var isDelaying: Bool { get set }
}

public protocol ProgressModelProtocol: DelayingCompletionProtocol {
    var progress: Progress? { get set }
}

public protocol ProgressDataModelProtocol: ProgressModelProtocol {
    associatedtype D
    
    var data: D? { get set }
}

open class DataProcessor<ModelType>: NSObject, DataProcessingProtocol {
    open func process(data: ModelType?) {
        assertionFailure("Need override function \(#function) to process data: \(String(describing: data))")
    }
}
