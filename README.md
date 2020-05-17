[![Version](https://img.shields.io/cocoapods/v/TangemSdk.svg?style=flat)](https://cocoapods.org/pods/TangemSdk)
[![License](https://img.shields.io/cocoapods/l/TangemSdk.svg?style=flat)](https://cocoapods.org/pods/TangemSdk)
[![Platform](https://img.shields.io/cocoapods/p/TangemSdk.svg?style=flat)](https://cocoapods.org/pods/TangemSdk)

# Welcome to Tangem

The Tangem card is a self-custodial hardware wallet for blockchain assets. The main functions of Tangem cards are to securely create and store a private key from a blockchain wallet and sign blockchain transactions. The Tangem card does not allow users to import/export, backup/restore private keys, thereby guaranteeing that the wallet is unique and unclonable. 

- [Getting Started](#getting-started)
	- [Requirements](#requirements)
	- [Installation](#installation)
		- [CocoaPods](#cocoapods)
		- [Swift Package Manager](#swift-package-manager)
		- [Carthage](#carthage)
- [Usage](#usage)
	- [Initialization](#initialization)
	- [Card interaction](#card-interaction)
		- [Scan card](#scan-card)
		- [Sign](#sign)
- [Customization](#customization)
	- [UI](#ui)
	- [Tasks](#tasks)
	- [Localization](#localization)


## Getting Started

### Requirements
iOS 11+ (CoreNFC is required), Xcode 11+

### Installation

1) Configure your app to detect NFC tags. Turn on Near Field Communication Tag Reading under the Capabilities tab for the project’s target (see [Add a capability to a target](https://help.apple.com/xcode/mac/current/#/dev88ff319e7)).

2) Add the [NFCReaderUsageDescription](https://developer.apple.com/documentation/bundleresources/information_property_list/nfcreaderusagedescription) key as a string item to the Info.plist file. For the value, enter a string that describes the reason the app needs access to the device’s NFC reader: 
```xml
<key>NFCReaderUsageDescription</key>
<string>Some reason</string>
```

3) In the Info.plist file, add the list of the application identifiers supported in your app to the [ISO7816 Select Identifiers](https://developer.apple.com/documentation/bundleresources/information_property_list/select-identifiers) (AIDs) information property list key. The AIDs of Tangem cards are: `A000000812010208` and `D2760000850101`.

```xml
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
    <array>
        <string>A000000812010208</string>
        <string>D2760000850101</string>
    </array>
```

4) To prevent customers from installing apps on a device that does not support the NFC capability, add the following to the Info.plist code:

 ```xml
<key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>nfc</string>
    </array>
```

#### CocoaPods

For the Tangem SDK, use the following entry in your Podfile:

```rb
pod 'TangemSdk'
```

Then run `pod install`.

For any file in which you'd like to use the Tangem SDK in, don't forget to
import the framework with `import TangemSdk`.

## Usage

Tangem SDK is a self-sufficient solution that implements a card abstraction model, methods of interaction with the card and interactions with the user via UI.

### Initialization
To get started, you need to create an instance of the `TangemSdk` class. It provides the simple way of interacting with the card.

```swift
let sdk = TangemSdk()
```

The universal initializer allows you to create an instance of the class that you can use immediately without any additional setup. 

You can also use a custom initializer, which allows you to pass your implementation of `CardReader` protocol to communicate with a card as well as the implementation of `SessionViewDelegate` protocol to create a custom user interface.
You can read more about this in [Customization](#сustomization).

### Basic usage
The easiest way to use the SDK is to call basic methods. All the basic methods you can find in `BasicUsage` extension of `TangemSdk` class. The basic method performs one or more operations and, after that, calls completion block with success or error.

Most of functions have the optional `cardId` argument, if it's passed the operation, it can be performed only with the card with the same card ID. If card is wrong, user will be asked to take the right card.
We recommend to set this argument if there is no special need to use any card.

When calling basic methods, there is no need to show the error to the user, since it will be displayed on the NFC popup before it's hidden.

**IMPORTANT**: You can't perform more then one basic function during the NFC session. In case you need to perform your own sequence of commands, take a look at [Advanced usage](#advanced-usage)

#### Scan card 
Method `scanCard()` is needed to obtain information from the Tangem card. Optionally, if the card contains a wallet (private and public key pair), it proves that the wallet owns a private key that corresponds to a public one.

Example:

```swift
tangemSdk.scanCard { result in
    switch result {
    case .success(let card):
        print("Read result: \(card)")
    case .failure(let error):
        print("Completed with error: \(error.localizedDescription), details: \(error)")
    }
}
```

#### Sign hashes
Method `sign(hashes: hashes, cardId: cardId)` allows you to sign one or multiple hashes. The SIGN command will return a corresponding array of signatures.

**Arguments:**

| Parameter | Description |
| ------------ | ------------ |
| hashes | Array of hashes to be signed by card |
| cardId | *(Optional)* If cardId is passed, the sign command will be performed only if the card  |


```swift
let hashes = [hash1, hash2]
let cardId = ...

tangemSdk.sign(hashes: hashes, cardId: cardId) { result in
    switch result {
    case .success(let signResponse):
        print("Result: \(signResponse)")
    case .failure(let error):
        print("Completed with error: \(error.localizedDescription), details: \(error)")
    }
}
```

### Advanced usage
Sometimes basic functions are not enough to achieve the goal. For instance, you want to sign some hashes and put some  data to a card.
To do it you can start Card Session by calling `tangemSdk.startSession(...)` and then implement everything you need in session callback function.

```swift
tangemSdk.startSession(cardId: nil) { session, error in
    //If session started wiithour errors
    //IF-LET-ERROR
    
    let readCommand = ReadCommand()
    //WHY-! ?
    readCommand!.run(in: session, completion: { result in
        switch result {
        case .success(let response1):
            DispatchQueue.main.async { // Switch to UI thread manually
                self.log(response1)
            }
            let checkWalletCommand = CheckWalletCommand(...)
            //WHY-! ?
            checkWalletCommand!.run(in: session, completion: { result in
                switch result {
                case .success(let response2):
                    DispatchQueue.main.async {
                        self.log(response2)
                    }
                    session.stop() // Close session manually
                case .failure(let error):
                    print(error)
                }
            })
        case .failure(let error):
            print(error)
        }
    })
}
```
But that is a manual mode, and in this case you should do some stuff by yourself:
1) Check that session is started successfully
2) Commands will not ...


## Customization
### UI
If the interaction with user is required, the SDK performs the entire cycle of this interaction. In order to change the appearance or behavior of the user UI, you can provide you own implementation of the `SessionViewDelegate` protocol. After this, initialize the `TangemSdk` class with your delegate class.

```swift
let mySessionViewDelegate = MySessionViewDelegate()
let tangemSdk = TangemSdk(cardReader: nil, viewDelegate: myCardManagerDelegate)
```

### Tasks
`TangemSdk` only covers general tasks. If you want to trigger card commands in a certain order, you have to options:

1) You can adopt `CardSessionRunnable` protocol and then use `run` method for your custom logic. You can run other commands and tasks via theirs `run` method.  You can use `ScanTask` as a reference.

Then call the `startSession(with runnable ...)` method of the `TangemSdk` class with you task.

```swift
let task = YourTask()
tangemSdk.startSession(with: task), completion: completion)
```

2) You can use `startSession(cardId: String?, initialMessage: String? = nil, delegate: @escaping (CardSession, SessionError?) -> Void)` method of the  `TangemSdk`

```swift
tangemSdk.startSession(cardId: nil) { session, error in
    let cmd1 = ReadCommand()
    cmd1!.run(in: session, completion: { result in
        switch result {
        case .success(let response1):
            DispatchQueue.main.async { // Switch to UI thread manually
                self.log(response1)
            }
            let cmd2 = CheckWalletCommand(...)
            cmd2!.run(in: session, completion: { result in
                switch result {
                case .success(let response2):
                    DispatchQueue.main.async {
                        self.log(response2)
                    }
                    session.stop() // Close session manually
                case .failure(let error):
                    print(error)
                }
            })
        case .failure(let error):
            print(error)
        }
    })
}
```

### Localization
You can replace one or more lines used in the SDK with your own. For this, you need to add keys with translations of the lines that you want to replace in your app, after which you need to install the localization bundle like this:
```swift
TangemSdk.Localization.localizationsBundle = Bundle(for: AppDelegate.self)
````
