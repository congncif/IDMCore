//
import IDMCore
//  ViewController.swift
//  IDMCore
//
//  Created by Nguyen Chi Cong on 08/16/2016.
//  Copyright (c) 2016 Nguyen Chi Cong. All rights reserved.
//

import UIKit

struct TestDelay: DelayingCompletionProtocol {
    var isDelaying: Bool
    var text: String
}

class DataProvider1: DataProviderProtocol {
    func request(parameters _: String?, completion: @escaping ((Bool, String?, Error?) -> Void)) -> (() -> Void)? {
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(3)) {
            completion(true, "result 1", nil)
//            completion(true, "result 2", nil)
//            completion(true, "result 3", nil)
//            completion(true, "result 4", nil)
//            completion(true, "result 5", nil)
        }

        return {}
    }
}

class DataProvider2: DataProviderProtocol {
    func request(parameters _: Int?, completion: @escaping ((Bool, TestDelay?, Error?) -> Void)) -> (() -> Void)? {
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(2)) {
            completion(false, TestDelay(isDelaying: true, text: "result 2"), nil)
        }

//        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(3)) {
//            completion(true, TestDelay(isDelaying: true, text: "result 3"), nil)
//        }
//
//        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(4)) {
//            completion(true, TestDelay(isDelaying: true, text: "result 4"), nil)
//        }
//
//        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(5)) {
//            completion(true, TestDelay(isDelaying: false, text: "result 5"), nil)
//        }

        return {}
    }
}

class ViewController: UIViewController {
    let retryService = AmazingIntegrator(dataProvider: DataProvider1())
    let service = AmazingIntegrator(dataProvider: DataProvider2())
//    let integrator = AmazingIntegrator(dataProvider: DataProvider2() >>>> DataProvider1())

//    let integrator2 = AmazingIntegrator(dataProvider: DataProvider1() >><< DataProvider2())

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        integrator.prepareCall().onSuccess { result in
//            print(result ?? "x")
//        }.call()
//
//        integrator2.prepareCall().onSuccess { results in
//            print(results ?? "x")
//        }.call()

//        let calls = ["", "", ""].map { p in
//            service.prepareCall().onSuccess({ (text) in
//                print("Success: \(text)")
//            })
//        }
//
//        IntegrationBatchCall.chant(calls: calls) { (result) in
//            print(result)
//        }

        let call = retryService.prepareCall()
            .onSuccess { res in
                print("Retry success: \(res)")
            }.onCompletion {
                print("Retry done")
            }

        service.prepareCall()
            .onBeginning({
                print("Start.....")
            })
            .onSuccess({ text in
                print("Success: \(text)")
            })
            .onCompletion({
                print("Completed")
            })
            .onError({ err in
                print(err)
            })
            .ignoreUnknownError(false)
            .retry(2, condition: {
                $0 == nil
            })
            .retryCall(call)
//            .call(dependOn: call)
            .call()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
