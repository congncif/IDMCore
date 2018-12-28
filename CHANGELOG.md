# Change Log
All notable changes to this project will be documented in this file.

#### 2.x Releases
- `2.8.x` Releases  - [2.8.0](#280) |  [2.8.1](#281)
- `2.7.x` Releases  - [2.7.0](#270) | [2.7.1](#271) | [2.7.2](#272) | [2.7.3](#273) |  | [2.7.8](#278)
- `2.6.x` Releases  - [2.6.0](#260) | [2.6.1](#261) | [2.6.2](#262) | [2.6.3](#263)  | [2.6.4](#264) | [2.6.5](#265) | [2.6.6](#266) | [2.6.7](#267)
- `2.5.x` Releases  - [2.5.0](#250)

---
## [2.8.1](https://github.com/congncif/IDMFoundation/releases/tag/2.8.1)
Released on 2018-12-28

#### Added
- Added `GroupIntegrator` to work with multiple Integrators.
- Added `DataProviderConverter` to convert an Integrator to DataProvider.

## [2.8.0](https://github.com/congncif/IDMFoundation/releases/tag/2.8.0)
Released on 2018-12-27

#### Updated
- Added `AbstractIntegrator` for generic declaring.
- Made `Integrator` to be subclass of ` AbstractIntegrator`
- Changed mechanism to identify `Integrator`

## [2.7.8](https://github.com/congncif/IDMFoundation/releases/tag/2.7.8)
Released on 2018-12-26

#### Updated
- Changed `IntegrationProtocol` which now is sub protocol of `IntegratorProtocol`

## [2.7.3](https://github.com/congncif/IDMFoundation/releases/tag/2.7.3)
Released on 2018-12-10

#### Updated
- Improved thread safe Integrator

## [2.7.0](https://github.com/congncif/IDMFoundation/releases/tag/2.7.0)
Released on 2018-11-18

#### Updated
- Added  `throws` to `ModelProtocol` for better error handling

## [2.6.7](https://github.com/congncif/IDMFoundation/releases/tag/2.6.7)
Released on 2018-5-5

#### Fixed
-  `Integration` cannot run with type `.only`

## [2.6.6](https://github.com/congncif/IDMFoundation/releases/tag/2.6.6)
Released on 2018-4-23

#### Updated
- Update `IntegrationCall` operators

## [2.6.4](https://github.com/congncif/IDMFoundation/releases/tag/2.6.4)
Released on 2018-4-19

#### Updated
- Progress protocol

## [2.6.3](https://github.com/congncif/IDMFoundation/releases/tag/2.6.3)
Released on 2018-4-19

#### Updated
- `IntegrationCall` nextSuccess, nextError : configuration with parameters
- `IntegrationCall`  added transformNext

## [2.6.2](https://github.com/congncif/IDMFoundation/releases/tag/2.6.2)
Released on 2018-4-17

#### Updated
- `IntegrationCall` nextSuccess, nextError with parametersBuilder

## [2.6.1](https://github.com/congncif/IDMFoundation/releases/tag/2.6.1)
Released on 2018-4-11

#### Updated
- IntegrationCall: Add onProgress to tracking

## [2.6.0](https://github.com/congncif/IDMFoundation/releases/tag/2.6.0)
Released on 2018-4-8

#### Updated
- Integrator now is sub-class of NSObject
- Added reference to get integrator from an integration call
- Update Integration Batch Call

## [2.5.0](https://github.com/congncif/IDMFoundation/releases/tag/2.5.0)
Released on 2018-4-3

#### Added
- Added IntegrationCall next operator
- Updated IntegrationBatchCall


## [1.0.0](https://github.com/congncif/IDMFoundation/releases/tag/1.0.0)

#### Added
- Initial release of IDMCore.
- Added by [NGUYEN CHI CONG](https://github.com/congncif).
