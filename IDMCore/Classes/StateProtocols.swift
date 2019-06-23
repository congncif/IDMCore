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
    associatedtype DataModel

    var data: DataModel? { get set }
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

extension LoadingHandler {
    public init<Handler>(handlerObject: Handler) where Handler: LoadingProtocol, Handler: AnyObject {
        self.init(beginHandler: { [weak handlerObject] in
            handlerObject?.beginLoading()
        }, finishHandler: { [weak handlerObject] in
            handlerObject?.finishLoading()
        })
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

extension ProgressLoadingHandler {
    public init<Handler>(handlerObject: Handler) where Handler: ProgressLoadingProtocol, Handler: AnyObject {
        self.init(beginHandler: { [weak handlerObject] in
            handlerObject?.beginProgressLoading()
        }, updateHandler: { [weak handlerObject] in
            handlerObject?.loadingDidUpdateProgress($0)
        }, finishHandler: { [weak handlerObject] in
            handlerObject?.finishProgressLoading()
        })
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

extension ErrorHandler {
    public init<Handler>(handlerObject: Handler) where Handler: ErrorHandlingProtocol, Handler: AnyObject {
        self.init { [weak handlerObject] in
            handlerObject?.handle(error: $0)
        }
    }
}

extension LoadingProtocol where Self: AnyObject {
    public func asLoadingHandler() -> LoadingProtocol {
        return LoadingHandler(handlerObject: self)
    }
}

extension ErrorHandlingProtocol where Self: AnyObject {
    public func asErrorHandler() -> ErrorHandlingProtocol {
        return ErrorHandler(handlerObject: self)
    }
}

extension ProgressLoadingProtocol where Self: AnyObject {
    public func asProgressLoadingHandler() -> ProgressLoadingProtocol {
        return ProgressLoadingHandler(handlerObject: self)
    }
}
