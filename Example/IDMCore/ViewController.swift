//
//  ViewController.swift
//  IDMCore
//
//  Created by Nguyen Chi Cong on 08/16/2016.
//  Copyright (c) 2016 Nguyen Chi Cong. All rights reserved.
//

import IDMCore
import UIKit

struct TestDelay: DelayingCompletionProtocol {
    var isDelaying: Bool
    var text: String
}

class DataProvider1: DataProviderProtocol {
    func request(parameters: NSError?, completionResult: @escaping (Result<String?, Error>) -> Void) -> CancelHandler? {
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(3)) {
            completionResult(.success("XXXX"))
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
    func request(parameters: Int?, completionResult: @escaping (Result<TestDelay?, Error>) -> Void) -> CancelHandler? {
        
        return {}
    }
}

class ABC: ProgressDataModelProtocol, ModelProtocol {
    var data: TestDelay?

    required init(fromData _: TestDelay?) throws {}

    var progress: Progress?

    var isDelaying: Bool = false
}

class ViewController: UIViewController {
    var exSer: AbstractIntegrator<Int, TestDelay>!
    lazy var groupSer: GroupIntegrator<AmazingIntegrator<DataProvider2>> = {
        GroupIntegrator<AmazingIntegrator<DataProvider2>>(creator: {
            AmazingIntegrator(dataProvider: DataProvider2())
        })
    }()

    let retryService = AmazingIntegrator(dataProvider: DataProvider1(), executingType: .only)
    let service = AmazingIntegrator(dataProvider: DataProvider2())
    let service2 = AmazingIntegrator(dataProvider: DataProvider2())
    let service3 = MagicalIntegrator(dataProvider: DataProvider2(), modelType: ABC.self)

    //    let integrator = AmazingIntegrator(dataProvider: DataProvider2() >>>> DataProvider1())

    //    let integrator2 = AmazingIntegrator(dataProvider: DataProvider1() >><< DataProvider2())

    override func viewDidLoad() {
        super.viewDidLoad()

        _ = BlockIntegrator<String, String> { $0 }

//        for i in 1...5 {
//            retryService.prepareCall().onSuccess { text in
//                print("Tak at: \(String(describing: text)) \(i)")
//            }
//            .call(delay: Double(i))
//        }
//
//        exSer = service

//        groupSer
//            .prepareCall(parameters: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
//            .onSuccess { result in
//                print(result.debugDescription)
//            }
//            .call()

//        exSer.prepareCall(parameters: 1).onError { err in
//            print(String(describing: err))
//        }.call()

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

    deinit {
        print("Deinit --> // >")
    }
}
