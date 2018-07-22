<img src="https://i.imgur.com/1z4dxIM.png"/>

# IDMCore

[![Version](https://img.shields.io/cocoapods/v/IDMCore.svg?style=flat)](http://cocoapods.org/pods/IDMCore)
[![License](https://img.shields.io/cocoapods/l/IDMCore.svg?style=flat)](http://cocoapods.org/pods/IDMCore)
[![Platform](https://img.shields.io/cocoapods/p/IDMCore.svg?style=flat)](http://cocoapods.org/pods/IDMCore)

**IDM** which represents for Integrator, Data Provider and Model is a new sub-pattern in MVC. This pattern will help you to build a better architecture. **IDMCore** is the heart of its. Can call this new model is **IDMVC** a branch of **MVC** but cleaner. It would be extremely accessible for everyone who is already familiar with MVC or beginners.

![alt text](http://i.imgur.com/Bw0caQ8m.png "IDMCore")

## Why IDMCore?

- **Make a Clean MVC**: Apply the principles to build, **IDMCore** makes your application become *easily to change*, *flexibly to scale*. It also enhances unit test capability, optimizes reuse of the parts of source code.

Writing code follows **IDMFoundation** and *IDM Template* is a great way to quickly create a flow (from requesting to handling response data). This will help eliminate the problem of *massive view controllers* which MVC often encounters, standardizes display loading and error warnings that many programmers feel uncomfortable. And many other utilities.

- **Unidirectional data flow**: The data flow will always go in one direction from the Data Provider to the Integrator to the controller. It makes it easy to control errors when they are occurs, readable and understandable.

- **Manage and ramification task**: Handling interdependent tasks, asynchronously tasks easily through Provider and IntegrationCall.

## How IDMCore?

### Installation

- For generic customize: using pure **IDMCore**

IDMCore is available through CocoaPods. To install it, simply add the following line to your Podfile:
```ruby
  pod 'IDMCore'
```

- For common iOS applications: using **IDMFoundation** which can find here: https://github.com/congncif/IDMFoundation

```ruby
  pod 'IDMFoundation/Core'
  pod 'IDMFoundation/RequestParameter'
  pod 'IDMFoundation/Alamofire'
  pod 'IDMFoundation/ObjectMapper'
  pod 'IDMFoundation/MBProgressHUD'
```

### Requirements

- iOS 8.0+
- Xcode 8.3+
- Swift 3.1+

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
                    print("Hide loading here")
                })
                .call()
```

***
Above is a simplest example to see how it works. Please look into many other tutorials about **IDMFoundation** to see the power of this pattern. More & more great features waiting to be explored.

### Thank you for reading!

## Author

Nguyen Chi Cong, congncif@gmail.com

## License

IDMCore is available under the MIT license. See the LICENSE file for more info.
