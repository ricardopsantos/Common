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

Common contains things like:

* Extensions
* Reachability manager
* App and device info utilities
* Generic utilities 
   * Networking
   * AuthManager
   * CacheManager
   * EncryptionManager
   * LocationManager
   * App Logger
   * Data types conversion tools

---

# Install

### Install via Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate RJPSLibUB into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "https://github.com/ricardopsantos/Common" "1.0.0"
```

or for beta

```ogdl
github "ricardopsantos/RJSLibUF" "master"
```

---

### Swift Package Manager

__Install using SPM On Xcode__

Add the following to your Package.swift file's dependencies:

`.package(url: "https://github.com/ricardopsantos/Common.git", from: "1.0.0")`

---

__Install using SPM on XcodeGen__

```yml
packages:
  Common:
    url: https://github.com/ricardopsantos/Common
    branch: main
    #minVersion: 1.0.0, maxVersion: 2.0.0
    
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

[https://github.com/kishikawakatsumi/KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess)

[https://github.com/roberthein/TinyConstraints](https://github.com/roberthein/TinyConstraints)
