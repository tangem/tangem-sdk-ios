[![Tests](https://github.com/tangem/tangem-sdk-ios/actions/workflows/tests.yml/badge.svg?branch=master)](https://github.com/tangem/tangem-sdk-ios/actions/workflows/tests.yml)
[![Version](https://img.shields.io/cocoapods/v/TangemSdk.svg?style=flat)](https://cocoapods.org/pods/TangemSdk)
[![License](https://img.shields.io/cocoapods/l/TangemSdk.svg?style=flat)](LICENSE)
![Platform](https://img.shields.io/cocoapods/p/TangemSdk)
[![Twitter](https://img.shields.io/twitter/follow/tangem?style=flat)](http://twitter.com/tangem)


# Welcome to Tangem

The Tangem card is a self-custodial hardware wallet that works via NFC. The main functions of Tangem cards are to securely create and store a private key and sign data.

Tangem SDK is needed to facilitate support for Tangem cards in third-party applications.

Supported platforms: **iOS** | [Android](https://github.com/tangem/tangem-sdk-android) | [JVM](https://github.com/tangem/tangem-sdk-android) | [Flutter](https://github.com/tangem/tangem-sdk-flutter) | [React Native ](https://github.com/tangem/tangem-sdk-react-native) | [Cordova](https://github.com/tangem/tangem-sdk-cordova) | [Capacitor](https://github.com/tangem/tangem-sdk-cordova)
 
# Documentation

For exhaustive documentation, see [developers.tangem.com](https://developers.tangem.com).

# Installation
## Requirements

iOS 13+ \(CoreNFC is required\), Xcode 12.5.1+  
SDK can be imported to a project with target version iOS 11, but it will be able to work only from iOS 13.

## Installation

Configure your app to detect NFC tags. Turn on Near Field Communication Tag Reading under the Capabilities tab for the project’s target \(see [Add a capability to a target](https://help.apple.com/xcode/mac/current/#/dev88ff319e7)\). 

When you adding **Near Field Communication Tag Reading** capability, Xcode generates entries in _\*.entitlement_ file. You should check that there are only the _Tag_ string in _com.apple.developer.nfc.readersession.formats_ array. Otherwise AppStore will reject your build when you try to upload it.

```markup
<key>com.apple.developer.nfc.readersession.formats</key>
<array>
    <string>TAG</string>
</array>
```

Add the [NFCReaderUsageDescription](https://developer.apple.com/documentation/bundleresources/information_property_list/nfcreaderusagedescription) key as a string item to the Info.plist file. For the value, enter a string that describes the reason the app needs access to the device’s NFC reader:

```markup
<key>NFCReaderUsageDescription</key>
<string>To scan NFC smart cards</string>
```

In the _Info.plist_ file, add the list of the application identifiers supported in your app to the [ISO7816 Select Identifiers](https://developer.apple.com/documentation/bundleresources/information_property_list/select-identifiers) \(AIDs\) information property list key.   
The AIDs of Tangem cards are: `A000000812010208` and `D2760000850101`.

```markup
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
    <array>
        <string>A000000812010208</string>
        <string>D2760000850101</string>
    </array>
```

**Optional:** To prevent customers from installing apps on a device that does not support the NFC capability, add the following to the Info.plist code:

```markup
<key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>nfc</string>
    </array>
```

### **CocoaPods**

For the Tangem SDK, use the following entry in your Podfile:

```bash
pod 'TangemSdk'
```

Then run `pod install`. 

Import Tangem SDK library:

```swift
import TangemSdk
```

# License

Tangem SDK is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
