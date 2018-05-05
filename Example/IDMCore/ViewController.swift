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
    func request(parameters: NSError?, completion: @escaping ((Bool, String?, Error?) -> Void)) -> (() -> Void)? {
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(3)) {
            completion(true, "result 1 input error: \(parameters)", NSError(domain: "retry error", code: 112, userInfo: nil))
            //            completion(true, "result 2", nil)
            //            completion(true, "result 3", nil)
            //            completion(true, "result 4", nil)
            //            completion(true, "result 5", nil)
        }

        return {}
    }
}

class Service: AmazingIntegrator<DataProvider1> {
    convenience init() {
        self.init(dataProvider: DataProvider1())
    }
}

class DataProvider2: DataProviderProtocol {
    func request(parameters _: Int?, completion: @escaping ((Bool, TestDelay?, Error?) -> Void)) -> (() -> Void)? {
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(2)) {
            completion(false, TestDelay(isDelaying: true, text: "result 2"), NSError(domain: "xxx", code: 1, userInfo: nil))
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
    let retryService = AmazingIntegrator(dataProvider: DataProvider1(), executingType: .only)
    let service = AmazingIntegrator(dataProvider: DataProvider2())
    let service2 = AmazingIntegrator(dataProvider: DataProvider2())
    let service3 = AmazingIntegrator(dataProvider: DataProvider2())
    //    let integrator = AmazingIntegrator(dataProvider: DataProvider2() >>>> DataProvider1())

    //    let integrator2 = AmazingIntegrator(dataProvider: DataProvider1() >><< DataProvider2())

    override func viewDidLoad() {
        super.viewDidLoad()
        
        retryService.prepareCall().onSuccess { (text) in
            print("Text: \(text)")
        }
        .call()
        
        retryService.prepareCall().onSuccess { (text) in
            print("Text: \(text)")
            }
            .call()
        
        retryService.prepareCall().onSuccess { (text) in
            print("Text: \(text)")
            }
            .call()
        
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

//        let call = retryService.prepareCall()
//            .onSuccess { res in
//                print("Retry success: \(res)")
//            }.onCompletion {
//                print("Retry done")
//            }

//        retryService.onSuccess { res in
//            print("Retry success: \(res)")
//        }
//
//        service
//            .ignoreUnknownError(false)
//            .retry(2) {
//                $0 != nil
//            }
//            .retryCall(AmazingIntegrator(dataProvider: DataProvider1()), state: .success)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        loadData()

//        service.prepareCall().onSuccess { res in
//            print("Success: \(res)")
//        }
//        .onCompletion({
//            print("Completeeeeeed")
//        }).call()
//        let call0 = service.prepareCall().onCompletion {
//            print("Call 0 done")
//        }
//
//        let call1 = service.prepareCall().onCompletion {
//            print("Call 1 done")
//        }
//
//        let call2 = service2.prepareCall().onCompletion {
//            print("Call 2 done")
//        }
//
//        let call3 = service3.prepareCall().onCompletion {
//            print("Call 3 done")
//        }
//
//        let call4 = retryService.prepareCall().onCompletion {
//            print("Call 4 done")
//        }

//        let x = (call1 --> call2 ->> call3)
//        x.call()
//
//        [call2, call1, call4, call5].call() {
//            _ in
//            print("XXXX")
//        }
        
//        [call1, call2, call3].call() {
//            _ in
//            print("XXX")
//        }

//        (call1 >-< call2 >-< call3 >-< call4).call() {
//            _ in
//            print("XLGD")
//        }
    }

    @IBAction func tap() {
//        loadData()
    }

    func loadData() {
//        let call = retryService.prepareCall()
//            .onSuccess { res in
//                print("Retry success: \(res)")
//            }.onCompletion {
//                print("Retry done")
//            }
//        service.throttle(delay: 3).prepareCall()
//            .onBeginning({
//                print("Start.....")
//            })
//            .onSuccess({ text in
//                print("Success: \(text)")
//            })
//            .onCompletion({
//                print("Completed")
//            })
//            .onError({ err in
//                print(err)
//            })
        ////            .retryIntegrator(retryService)
//            .retryCall(call)
//            .call()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
