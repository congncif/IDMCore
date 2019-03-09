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

public protocol LoadingObjectProtocol: AnyObject, LoadingProtocol {}

public protocol ProgressLoadingProtocol {
    func beginProgressLoading()
    func loadingDidUpdateProgress(_ progress: Progress?)
    func finishProgressLoading()
}

public protocol ProgressLoadingObjectProtocol: AnyObject, ProgressLoadingProtocol {}

public protocol ErrorHandlingProtocol {
    func handle(error: Error?)
}

public protocol ErrorHandlingObjectProtocol: AnyObject, ErrorHandlingProtocol {}

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

open class AbstractDataProcessor<ModelType>: DataProcessingProtocol {
    public init() {}

    open func process(data: ModelType?) {
        assertionFailure("Need override function \(#function) to process data: \(String(describing: data))")
    }
}

public struct DataProcessor<ModelType>: DataProcessingProtocol {
    public var dataProcessing: (ModelType?) -> Void

    public init(dataProcessing: @escaping (ModelType?) -> Void) {
        self.dataProcessing = dataProcessing
    }

    public func process(data: ModelType?) {
        dataProcessing(data)
    }
}

public struct LoadingHandler: LoadingProtocol {
    private let beginHandler: () -> Void
    private let finishHandler: () -> Void

    public init(beginHandler: @escaping () -> Void, finishHandler: @escaping () -> Void) {
        self.beginHandler = beginHandler
        self.finishHandler = finishHandler
    }

    public func beginLoading() {
        beginHandler()
    }

    public func finishLoading() {
        finishHandler()
    }
}

public struct ProgressLoadingHandler: ProgressLoadingProtocol {
    private let beginHandler: () -> Void
    private let finishHandler: () -> Void
    private let updateHandler: (Progress?) -> Void

    public init(beginHandler: @escaping () -> Void,
                updateHandler: @escaping (Progress?) -> Void,
                finishHandler: @escaping () -> Void) {
        self.beginHandler = beginHandler
        self.finishHandler = finishHandler
        self.updateHandler = updateHandler
    }

    public func beginProgressLoading() {
        beginHandler()
    }

    public func loadingDidUpdateProgress(_ progress: Progress?) {
        updateHandler(progress)
    }

    public func finishProgressLoading() {
        finishHandler()
    }
}

public struct ErrorHandler: ErrorHandlingProtocol {
    private let handler: (Error?) -> Void

    public init(handler: @escaping (Error?) -> Void) {
        self.handler = handler
    }

    public func handle(error: Error?) {
        handler(error)
    }
}

public struct ErrorHandlingProxy: ErrorHandlingProtocol {
    private var handlersDict: [String: ErrorHandlingProtocol]
    private var errorConditions: [String: (Error?) -> Bool] = [:]

    public init(handlers: [ErrorHandlingProtocol] = []) {
        let payload = handlers.map { (key: String(describing: $0), value: $0) }
        handlersDict = payload.reduce([:]) { result, item in
            var newResult = result
            newResult[item.key] = item.value
            return newResult
        }
    }

    private var handlers: [ErrorHandlingProtocol] {
        return Array(handlersDict.values)
    }

    public func handle(error: Error?) {
        handlers.forEach {
            let key = String(describing: $0)
            if let condition = errorConditions[key] {
                if condition(error) {
                    $0.handle(error: error)
                }
            } else {
                $0.handle(error: error)
            }
        }
    }

    public mutating func addHandler(_ handler: ErrorHandlingProtocol,
                                    where condition: ((Error?) -> Bool)? = nil) {
        let key = String(describing: handler)
        handlersDict[key] = handler
        errorConditions[key] = condition
    }

    public mutating func removeHandler(_ handler: ErrorHandlingProtocol) {
        let key = String(describing: handler)
        handlersDict.removeValue(forKey: key)
        errorConditions.removeValue(forKey: key)
    }

    public mutating func removeAllHandlers() {
        handlersDict.removeAll()
        errorConditions.removeAll()
    }
}

extension LoadingObjectProtocol {
    public func asValueType() -> LoadingProtocol {
        return LoadingHandler(beginHandler: { [weak self] in
            self?.beginLoading()
        }, finishHandler: { [weak self] in
            self?.finishLoading()
        })
    }
}

extension ErrorHandlingObjectProtocol {
    public func asValueType() -> ErrorHandlingProtocol {
        return ErrorHandler { [weak self] in
            self?.handle(error: $0)
        }
    }
}

extension ProgressLoadingObjectProtocol {
    public func asValueType() -> ProgressLoadingProtocol {
        return ProgressLoadingHandler(beginHandler: { [weak self] in
            self?.beginProgressLoading()
        }, updateHandler: { [weak self] in
            self?.loadingDidUpdateProgress($0)
        }, finishHandler: { [weak self] in
            self?.finishProgressLoading()
        })
    }
}
