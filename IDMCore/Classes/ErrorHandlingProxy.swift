//
//  ErrorHandlingProxy.swift
//  IDMCore
//
//  Created by NGUYEN CHI CONG on 3/21/19.
//

import Foundation

public struct ErrorHandlingProxy: ErrorHandlingProtocol {
    public typealias Condition = (Error?) -> Bool

    public enum HandlingPriority {
        case `default`
        case high
        case medium
        case low
        case specific(UInt)

        public var value: UInt {
            var _value: UInt
            switch self {
            case .default:
                _value = 0
            case .low:
                _value = 250
            case .medium:
                _value = 750
            case .high:
                _value = 1000
            case .specific(let val):
                _value = val
            }
            return _value
        }
    }

    public enum HandlingType {
        case independence // The error will be forwarded to all sub-handlers to handle
        case chain // The error will be forwarded turn in turn through each sub-handler until it is handled
    }

    private struct HandlerInfo {
        var handler: ErrorHandlingProtocol
        var condition: Condition?
        var priority: UInt

        var identifier: String {
            return String(describing: handler)
        }
    }

    public let type: HandlingType
    private var handlersDict: [String: HandlerInfo]

    public init(type: HandlingType = .independence) {
        self.type = type
        handlersDict = [:]
    }

    public var handlers: [ErrorHandlingProtocol] {
        return sortedHandlersInfo.map { $0.handler }
    }

    private var sortedHandlersInfo: [HandlerInfo] {
        return Array(handlersDict.values).sorted { $0.priority > $1.priority }
    }

    public func handle(error: Error?) {
        let handlersInfo = sortedHandlersInfo

        for info in handlersInfo {
            if let condition = info.condition {
                if condition(error) {
                    info.handler.handle(error: error)
                    if case .chain = type { break }
                }
            } else {
                info.handler.handle(error: error)
                if case .chain = type { break }
            }
        }
    }

    public mutating func addHandler(
        _ handler: ErrorHandlingProtocol,
        priority: HandlingPriority = .default,
        where condition: Condition? = nil
    ) {
        let info = HandlerInfo(handler: handler, condition: condition, priority: priority.value)
        let key = info.identifier
        handlersDict[key] = info
    }

    public mutating func removeHandler(_ handler: ErrorHandlingProtocol) {
        let key = String(describing: handler)
        handlersDict.removeValue(forKey: key)
    }

    public mutating func removeAllHandlers() {
        handlersDict.removeAll()
    }
}

extension ErrorHandlingProxy {
    public typealias DedicatedCondition<T> = (T) -> Bool

    public mutating func addDedicatedHandler<E>(
        _ handler: DedicatedErrorHandler<E>,
        priority: HandlingPriority = .default,
        where condition: DedicatedCondition<E>? = nil
    ) {
        let wrappedCondition: Condition = { error in
            guard let error = error as? E else {
                return false
            }
            guard let condition = condition else {
                return true
            }
            return condition(error)
        }
        let info = HandlerInfo(handler: handler, condition: wrappedCondition, priority: priority.value)
        let key = info.identifier
        handlersDict[key] = info
    }
}
