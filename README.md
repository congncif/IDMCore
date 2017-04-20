# IDMCore

[![Version](https://img.shields.io/cocoapods/v/IDMCore.svg?style=flat)](http://cocoapods.org/pods/IDMCore)
[![License](https://img.shields.io/cocoapods/l/IDMCore.svg?style=flat)](http://cocoapods.org/pods/IDMCore)
[![Platform](https://img.shields.io/cocoapods/p/IDMCore.svg?style=flat)](http://cocoapods.org/pods/IDMCore)

## Installation

IDMCore is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "IDMCore"
```

## Author

Nguyen Chi Cong, congncif@gmail.com

## License

IDMCore is available under the MIT license. See the LICENSE file for more info.

## Example ##
http://github.com/congncif/IDM-Data-Flow  
This is a sample which conforms IDM Data Flow.

***

# IDMCore

Integrator - Data Provider - Model : Make your iOS MVC application cleaner.

IDMCore is an implementation of the unidirectional data flow architecture in Swift. IDMCore helps you to separate three important concerns of your data flow components:

* **Model** : model of data used in controller to render views.
* **DataProvider** : provides methods to retrieve data from the storage source or initialization data.
* **Integrator** : dispatches integration call to Data Providers and retrieve the desired data model.
 
![alt text](http://i.imgur.com/Bw0caQ8m.png "IDMCore")

### Requirements
  - XCode 8+, Swift 3+
  - iOS 8+

* Swift 3.0+ : use v1.x
* Swift 3.1+: use v2.x

### Installation
IDMCore is available through CocoaPods. To install it, simply add the following line to your Podfile:

```ruby
pod 'IDMCore'
```

### Getting started

**1. Create a Data provider to fetch data**

A Data provider conforms `DataProviderProtocol`. You need implement `request` method to request data, which specify input parameters type and ouput data type. This also return a closure, which can cancel request.

```swift
func request(parameters: <#input_type#>?, completion: ((Bool, <#output_type#>?, Error?) -> ())?) -> (() -> ())?
```

Example:

```swift
struct UserDataProvider: DataProviderProtocol {
    func request(parameters: String?, completion: ((Bool, [String: AnyObject]?, Error?) -> ())?) -> (() -> ())? {
        let query = parameters ?? "default"
        let apiPath = "https://api.github.com/search/users?q=\(query)"
        let request = Alamofire.request(apiPath, method: .get )
        request.responseJSON { (response) in
            var success = true
            var data: [String: AnyObject]? = nil
            var error: NSError? = nil
            defer {
                completion?(success, data, error)
            }
            let value = response.result.value
            guard value != nil else {
                return
            }
            data = value as? [String: AnyObject]
        }
        return {
            request.cancel()
        }
    }
}
```

**2. Create a Model**

A Model conforms `ModelProtocol`. You need implement `init(from:)` method to parse data.
```swift
init?(from data: <#input_data_type#>?)
```

Example:

```swift
struct Users: ModelProtocol {
    
    var items: [User]?
    
    init(from data: [String : AnyObject]?) {
        guard data != nil else {return}
        guard let items = data!["items"] as? [[String: AnyObject]] else {
            return
        }
        var users:[User] = []
        
        for item in items {
            let u = User(from: item)
            users.append(u)
        }
        self.items = users
    }
}

struct User: ModelProtocol {

    var userName: String?
    var avatarUrl: String?
    var homeUrl: String?
    
    init(from data: [String : AnyObject]?) {
        guard data != nil else {return}
        
        let userName = data!["login"] as? String
        let url = data!["avatar_url"] as? String
        let homeUrl = data!["html_url"] as? String
        
        self.userName = userName
        self.avatarUrl = url
        self.homeUrl = homeUrl
    }
}
```

**3. Integrate with Controller**

A Integrator like an use case of data flow. Declare an integrator & initialize with Data provider & Model type.

```swift
class UsersViewController: UIViewController , UITableViewDataSource {
[...]
var integrator = MagicalIntegrator(dataProvider: UserDataProvider(), modelType: Users.self)
}
```

Call integrator to get data & handle returned model:

```swift
            integrator
                .prepareCall(parameters: "apple")
                .onBeginning({
                    print("Show loading here")
                })
                .onSuccess({ (users) in
                    self.users = users?.items ?? []
                })
                .onError({ (error) in
                    print("Error: \(error)")
                })
                .onCompletion({
                    self.tableView.reloadData()
                    print("Hide loading here")
                })
                .call()
```

### Why IDMCore?

##### *Keep your application's data flow clear*

There are some practical experiences, which usually are used by many developers : `APIClient`.
This component contains many APIs to request data from remote server. Of course, you don't want to use this data in your flow. So, you need to parse to data model.

It may look like this example:
```swift
class APIClient {
    func getUsers(parameters: String, completion: ((Bool, Users, Error?) -> ())?) {
        let apiPath = "https://api.github.com/search/users?q=\(parameters)"
        let request = Alamofire.request(apiPath, method: .get )
        request.responseJSON { (response) in
            var success = true
            var data: Users?
            var error: NSError? = nil
            let value = response.result.value
            
            <#parse value to Users model#>
            
            completion?(success, data, error)
        }
    }
}
```

You can see it is quite cool & easy to use. It also is right about functionally. But wait a bit... With `APIClient`, you put request code and parse code together. This leads you can hardly write unit tests for only the requesting data. If has an error occurred with this API method, you will have to determine where the error occurred, data from requesting isn't correct or parsing doesn't work right. A good idea would be to separate the parsing data out and return the original data from the server. This means that each api call to be accompanied by a parsing data call before using. That's something you never want to do when you integrate it into your application. Your code is not friendly for use and not look nice.

With IDMCore, I use Data provider for requesting data. Data provider has *dynamic input type* and *dynamic output type*, so you can specify any type you want. You should complete provider with original data.  Model should contain method to parse data for itself. And Integrator like a synthesis of all these things and take out what you need. OK. From here, you can write unit tests for requesting data, for parsing data, for integration. All became clear, right?

>IDMCore also allows use output of Data provider as final Model with `AmazingIntegrator`

##### *Easy working with multiple Data providers*
* **Sequence Data Provider**: Create a Sequence Data Provider if you want to request data which depend on result of requesting data from another where. ***Output of previous Provider is input of next Provider***. Output of last Provider is output of Sequence Provider. Using operator `>>>>` to create Sequence provider:

```swift
let integrator = AmazingIntegrator(dataProvider: DataProvider2() >>>> DataProvider1())
```

* **Group Data Provider**: Create a Group Data Provider if you want to request data from many sources and combine all outputs when all requests finished (All requests is asynchronous). Output of Group provider is a tuple data of all outputs from sub-providers. Using operator `>><<` to create Group provider:
```swift
let integrator2 = AmazingIntegrator(dataProvider: DataProvider1() >><< DataProvider2())
```
##### *Easy controlling the integration call by `executingType`*
```swift
case `default`    // All integration calls will be executed independently
    case only       // Only single integration call is executed at the moment, all integration calls arrive when current call is running will be ignored
    case queue      // All integration calls will be added to queue to execute
    case lastest    // The integration will cancel all integration call before & only execute lastest integration call
```
* For searching: you can use `.lastest`
* For submitting: you can use `.only`

Example:

```swift
 var integrator = MagicalIntegrator(dataProvider: UserDataProvider(), modelType: Users.self, executingType:.lastest)
```

##### *Next integration call*

An integration call is created when you use `prepareCall` method of an `Integrator` to integrate data flow . 
Ordering the works that integration call do: `onBeginning` -> `onSuccess` ***or*** `onError` -> `onCompletion`.
**IDMCore** supports "**next integration call**" to an integration call continues calling to an another integration call when finished.

* `nextSuccess` call after `onSuccess`
* `nextError` call after `onError`
* `nextCompletion` call after `onCompletion`
* `fowardSuccess` call an another integration call after `onSuccess` with paramter is result in `onSuccess`
* `forwardError` call an another integration call after `onError` with paramter is result in `onError`
* `thenRecall` call an another integration call after `onCompletion` with ***same Model type***. Both use `onBeginning`, `onSuccess`, `onError`, `onCompletion`

*This may be useful when you want to preload data from cache before requesting server:*
```swift
        integratorCache
            .prepareCall()
            .onBeginning({ 
                print("Show loading")
            })
            .onSuccess { (text) in
                print(text)
            }
            .onError({ (error) in
                print(error)
            })
            .onCompletion({ 
                print("Hide loading")
            })
            .thenRecall(with: integratorServer)
            .call()
```

***
More & more great features waiting to be explored.
### Thank you for reading!