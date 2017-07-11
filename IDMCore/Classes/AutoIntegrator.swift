//
//  AutoIntegrator.swift
//  IDMCore
//
//  Created by NGUYEN CHI CONG on 9/15/16.
//  Copyright © 2016 NGUYEN CHI CONG. All rights reserved.
//

import Foundation

open class MagicalIntegrator<IntegrateProvider: DataProviderProtocol, IntegrateModel: ModelProtocol>: Integrator<IntegrateProvider, IntegrateModel, IntegrateModel> where IntegrateProvider.DataType == IntegrateModel.DataType {

    public override init(dataProvider: IntegrateProvider, modelType: IntegrateModel.Type, executingType: IntegrationType = .default) {
        super.init(dataProvider: dataProvider, modelType: modelType, executingType: executingType)
    }
}

open class AmazingIntegrator<IntegrateProvider: DataProviderProtocol>: Integrator<IntegrateProvider, AutoWrapModel<IntegrateProvider.DataType>, IntegrateProvider.DataType> {

    public init(dataProvider: IntegrateProvider, executingType: IntegrationType = .default) {
        super.init(dataProvider: dataProvider, modelType: AutoWrapModel<IntegrateProvider.DataType>.self, executingType: executingType)
    }
}

open class AdvancedIntegrator<IntegrateProvider: DataProviderProtocol, IntegrateModel: ModelProtocol, ResultModel>: Integrator<IntegrateProvider, IntegrateModel, ResultModel> where IntegrateProvider.DataType == IntegrateModel.DataType {

    public init(dataProvider: IntegrateProvider, modelType: IntegrateModel.Type, resultType _: ResultModel.Type, executingType: IntegrationType = .default) {
        super.init(dataProvider: dataProvider, modelType: modelType, executingType: executingType)
    }
}
