/**
 Copyright (c) 2016 Nguyen Chi Cong

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

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

    public convenience init(dataProvider: DataProviderType, executingType: IntegrationType = .default) {
        self.init(dataProvider: dataProvider, modelType: IntegrateModel.self, executingType: executingType)
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
