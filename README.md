<img src="https://i.imgur.com/1z4dxIM.png"/>

# IDMCore

[![Version](https://img.shields.io/cocoapods/v/IDMCore.svg?style=flat)](http://cocoapods.org/pods/IDMCore)
[![License](https://img.shields.io/cocoapods/l/IDMCore.svg?style=flat)](http://cocoapods.org/pods/IDMCore)
[![Platform](https://img.shields.io/cocoapods/p/IDMCore.svg?style=flat)](http://cocoapods.org/pods/IDMCore)

**IDM** which represents for `Integrator`, `Data Provider` and `Model` is core concepts of `Interactor/Domain` layer which makes your app:

* Independently with `Database` and `external agency` via `Data Providers`.
* Build an `unidirectional data flow`.
* Manage async tasks by `Integrator queues`. 

*This pattern will help you to build a better architecture and provide a set of utilities to handle complex business logic of your app.*

![alt text](https://i.imgur.com/cOVvHbu.jpg)

## Why IDMCore?

- **Make a clean structure**: Apply the principles of design, **IDMCore** makes your application become *easily to change*, *flexibly to scale*. It also enhances unit test capability, optimizes reuse of the parts of source code. It is especially compatible with most of today's popular application architectures from **MVC**, **MVP** to **VIPER**.

  * With **MVC**, the framework helps to eliminate the problems of *massive view controllers* which MVC often encounters, standardizes display loading and error warnings that many programmers feel uncomfortable.

  * With **MVP** and **VIPER**, the framework helps to eliminate repeatable delegate methods between presenter and view whose sole purpose is forward a signal, such as *startLoading*, *successHandling* or *errorHandling*.

- **Unidirectional data flow**: The data flow will always go in one direction from the `View` to `Integrator` to `DataProvider`. It makes this easy to control errors when they are occurs, readable and understandable. In addition, each data provider is responsible for retrieving the data required by the `Integrator`, so you can completely replace it with another one with similar functionality, or aggregate data from multiple different data providers. Your application will be independent of the data sources that will help you ***mock up test data*** easily.

- **Manage tasks**: Handling interdependent tasks, asynchronously tasks easily through `IntegrationCall`. Scheduling data providers lets you control tasks without the need to add a large library just to manage tasks.

## How IDMCore?

### Installation

### CocoaPods

```ruby
  pod 'IDMCore'
```

### Carthage

```
github "congncif/IDMCore"
```

* **IDMFoundation**(https://github.com/congncif/IDMFoundation) with default implementation `IDMCore` with `Alamofire` and `ObjectMapper` will help you create an IDM flow easily.

* **ModuleX**(https://github.com/congncif/ModuleX) with modularization mindset will help you create a clean architecture of mobile app.

### Tools

You can use below templates to quickly create an `IDM data flow` or `ModuleX module` *(They are available in above repos)*.

* **ModuleX Template** generates a standalone module using `ModuleX` concept.
* **IDMCore Template** generates a data flow using `IDMCore` concept.

### Requirements

- iOS 8.0+
- Xcode 8.3+
- Swift 3.1+

### Getting started

**IDMFoundation**🐴 together with **ViewStateCore**🐥 and **ModuleX**🐶 will make your application to ***absolute control***. 💪💪💪

https://github.com/congncif/IDMFoundation

https://github.com/congncif/ViewStateCore

https://github.com/congncif/ModuleX

### Thank you for reading!

## Author

Nguyen Chi Cong, congncif@gmail.com

## License

IDMCore is available under the MIT license. See the LICENSE file for more info.
