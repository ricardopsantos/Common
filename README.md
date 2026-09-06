# RJS_Common

__Guys love tools, this is my Swift toolbox (UIKit, Foundation, SwiftUI & Combine)__

<p align="center">
   <a href="https://developer.apple.com/swift/">
      <img src="https://img.shields.io/badge/Swift-5.1-orange.svg?style=flat" alt="Swift 5.3">
   </a>
    <a href="https://developer.apple.com/swift/">
      <img src="https://img.shields.io/badge/Xcode-15.4.-blue.svg" alt="Swift 5.3">
   </a>
   <a href="">
      <img src="https://img.shields.io/cocoapods/p/ValidatedPropertyKit.svg?style=flat" alt="Platform">
   </a>
   <br/>
   <a href="https://github.com/Carthage/Carthage">
      <img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" alt="Carthage Compatible">
   </a>
   <a href="https://github.com/apple/swift-package-manager">
      <img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg" alt="SPM">
   </a>
   <a href="https://twitter.com/ricardo_psantos/">
      <img src="https://img.shields.io/badge/Twitter-@ricardo_psantos-blue.svg?style=flat" alt="Twitter">
   </a>
</p>


# Library Organization

`Common` is a single SPM target (`Sources/`), grouped by concern. Everything is
namespaced under `Common`, `CommonNetworking`, `CommonCoreData` or
`Common_PropertyWrappers`, so nothing leaks into the global namespace.

### Extensions

Additive-only helpers on system types — no behaviour is replaced.

| Folder | Covers |
| --- | --- |
| `ExtensionsFoundation/` | `String`, `Date`, `Data`, `NSPredicate`, `CLPlacemark`, collections |
| `ExtensionsUI/` | `UIView` (incl. an AutoLayout DSL), `UIColor`, `UIImage`, `UIStackView`, `WKWebView` |
| `ExtensionsCombine/` | `AnyPublisher` operators and the Combine → `async/await` bridge |
| `SwiftUI/` | `View` modifiers and conditionals, `Binding`, `Color`, `Image`, preference keys, UIKit interop |
| `Combine/` | `CombineCompatible` (`.publisher` on UIKit controls) and custom subscribers |

### Managers

Stateful services, each usable on its own.

| Manager | Purpose |
| --- | --- |
| `CacheManagers/` | Codable caching over three backends — Core Data, `NSCache`, `UserDefaults` |
| `CronometerManager/` | Named timers and averaged duration metrics |
| `FilesManager/` | Sandbox file and image storage |
| `LocationManager/` | Shared `CLLocationManager` wrapper with a single-shot and a streaming API |
| `CameraManager` | Capture-session wrapper |
| `CloudKitManager` | CloudKit record CRUD |
| `EncryptionManager` / `SymmetricKeyManager` | CryptoKit encryption with Keychain-backed keys |
| `AuthenticationManager` / `BiometricAuthManagerViewModel` | Face ID / Touch ID flows |
| `LogsManager` | Levelled logging with optional on-disk persistence |
| `UserDefaultsManager` | Typed `UserDefaults` access |
| `ExecutionControlManager` | `throttle`, `debounce`, `executeOnce`, `takeFirst` / `dropFirst` |
| `ThreadingManager` | Locking primitives (`NSLock`, `os_unfair_lock`, `objc_sync`) |
| `KeyboardManager` | Keyboard frame and visibility publisher |
| `NetworkMonitorViewModel` | Observable connectivity state |

### Networking

`Sources/Networking/` — a Combine-based API client (`NetworkAgentClient`) with
async/await wrappers, certificate-pinning support, typed `APIError` and
`HTTPStatusCode`, request/response logging with cURL dumps, JSON and CSV
decoding, image downloading with a caching policy, plus `Reachability` and
`NWPathMonitor`-based connectivity checks.

### Core Data

`Sources/CData/` — a wrapper over `NSPersistentContainer` offering sync and
async CRUD, main- and private-queue fetch paths, and a Codable record store
used by the cache managers.

### Property wrappers

`Sources/PropertyWrappers/` — all exported as `PW`-prefixed typealiases:
`@PWUserDefaults` and `@PWKeychainStorageV1` / `V2` are `DynamicProperty`, so
SwiftUI views refresh on write; `@PWThreadSafe` synchronises a stored property
behind `os_unfair_lock`; `@PWInject` / `@PWInjectContainer` provide a small
dependency-injection container; `@PWProjectedOnChange` and `@PWPartialState`
cover change observation and partial state updates.

### Utilities and value types

`Sources/Utils/` — `AppAndDeviceInfo`, `CancelBag` (an ID-keyed
`AnyCancellable` store with auto-release), and assorted conversion helpers.
`Sources/ValueTypes/` — the DTO / model protocols the networking and Core Data
layers are written against.

### Vendored

`Sources/3Party/` — [Keychain](https://github.com/kishikawakatsumi/KeychainAccess)
and [TinyConstraints](https://github.com/roberthein/TinyConstraints), inlined so
the package has no runtime dependencies.

### Not part of the library

`Sources/Learnings/` holds annotated SwiftUI, Combine and concurrency samples.
They ship in the target but are reference material, not API.

---

# Install

### Install via Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate Common into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "https://github.com/ricardopsantos/Common" "1.4.0"
```

or for beta

```ogdl
github "ricardopsantos/Common" "master"
```

---

### Swift Package Manager

__Install using SPM On Xcode__

Add the following to your Package.swift file's dependencies:

`.package(url: "https://github.com/ricardopsantos/Common.git", from: "1.4.0")`

---

__Install using SPM on XcodeGen__

```yml
packages:
  Common:
    url: https://github.com/ricardopsantos/Common
    branch: main
    #minVersion: 1.0.0, maxVersion: 1.5.0
    
targets:
  YourAppTargetName:
    type: application
    platform: iOS
    deploymentTarget: "15.0"
    sources:
       - path: ../YourAppSourcePath
    dependencies:
      - package: Common
        product: Common
```

---
        
# 3 party code

* [https://github.com/kishikawakatsumi/KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess)

* [https://github.com/roberthein/TinyConstraints](https://github.com/roberthein/TinyConstraints): At [/Sources/3Party/TinyConstraints](https://github.com/ricardopsantos/Common/tree/main/Sources/3Party/TinyConstraints) there is a changed version of this library with some methods added and also changes (every contraints has a unique ID for an easier get/set of a specific constraint)
