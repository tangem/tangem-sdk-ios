[![Version](https://img.shields.io/cocoapods/v/TangemSdk.svg?style=flat)](https://cocoapods.org/pods/TangemSdk)
[![License](https://img.shields.io/cocoapods/l/TangemSdk.svg?style=flat)](https://cocoapods.org/pods/TangemSdk)
[![Platform](https://img.shields.io/cocoapods/p/TangemSdk.svg?style=flat)](https://cocoapods.org/pods/TangemSdk)


# Welcome to Tangem

The Tangem card is a self-custodial hardware wallet for blockchain assets. The main functions of Tangem cards are to securely create and store a private key from a blockchain wallet and sign blockchain transactions. The Tangem card does not allow users to import/export, backup/restore private keys, thereby guaranteeing that the wallet is unique and unclonable. 

- [Getting Started](#getting-started)
	- [Requirements](#requirements)
	- [Installation](#installation)
		- [CocoaPods](#cocoapods)
- [Usage](#usage)
	- [Initialization](#initialization)
	- [Basic usage](#basic-usage)
		- [Scan card](#scan-card)
		- [Sign](#sign-hashes)
    - [Advanced usage](#advanced-usage)
        - [Starting custom session](#starting-custom-session)
- [Customization](#customization)
	- [UI](#ui)
	- [Localization](#localization)


## Getting Started

### Requirements
iOS 13+ (CoreNFC is required), Xcode 12+

SDK can be imported to iOS 11, but it will work only since iOS 13.

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

#### Sign
Method `sign(hashes: hashes, cardId: cardId)` allows you to sign one or multiple hashes. The SIGN command will return a corresponding array of signatures.

**Arguments:**

| Parameter | Description |
| ------------ | ------------ |
| cardId | *(Optional)* If cardId is passed, the sign command will be performed only if the card  |
| hashes | Array of hashes to be signed by card |


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

#### Wallet
##### Create Wallet
Method `tangemSdk.createWallet(cardId: cardId)` will create a new wallet on the card. A key pair `WalletPublicKey` / `WalletPrivateKey` is generated and securely stored in the card.

##### Purge Wallet
Method `tangemSdk.purgeWallet(cardId: cardId)` deletes all wallet data.

#### Issuer data
Card has a special 512-byte memory block to securely store and update information in COS. For example, this mechanism could be employed for enabling off-line validation of the wallet balance and attesting of cards by the issuer (in addition to Tangem’s attestation). The issuer should define the purpose of use, payload, and format of Issuer Data field. Note that Issuer_Data is never changed or parsed by the executable code the Tangem COS. 

The issuer has to generate single Issuer Data Key pair `Issuer_Data_PublicKey` / `Issuer_Data_PrivateKey`, same for all issuer’s cards. The private key Issuer_Data_PrivateKey is permanently stored in a secure back-end of the issuer (e.g. HSM). The non-secret public key Issuer_Data_PublicKey is stored both in COS (during personalization) and issuer’s host application that will use it to validate Issuer_Data field.

##### Write issuer data
Method `tangemSdk.writeIssuerData(cardId: cardId,issuerData: sampleData, issuerDataSignature: dataSignature, issuerDataCounter: counter)` writes 512-byte Issuer_Data field to the card.

**Arguments:**

| Parameter | Description |
| ------------ | ------------ |
| cardId | *(Optional)* If cardId is passed, the sign command will be performed only if the card  |
| issuerData | Data to be written to the card |
| issuerDataSignature | Issuer’s signature of issuerData with `Issuer_Data_PrivateKey` |
| issuerDataCounter | An optional counter that protect issuer data against replay attack. When flag Protect_Issuer_Data_Against_Replay set in the card configuration then this value is mandatory and must increase on each execution of `writeIssuerData` command.  |

##### Write issuer extra data
If 512 bytes are not enough, you can use method `tangemSdk.writeIssuerExtraData(cardId: cardId, issuerData: sampleData,startingSignature: startSignature,finalizingSignature: finalSig,issuerDataCounter: newCounter)` to save up to 40 kylobytes.

| Parameter | Description |
| ------------ | ------------ |
| cardId | *(Optional)* If cardId is passed, the sign command will be performed only if the card  |
| issuerData | Data to be written to the card |
| startingSignature | Issuer’s signature of `SHA256(cardId | Size)` or `SHA256(cardId | Size | issuerDataCounter)` with `Issuer_Data_PrivateKey` |
| finalizingSignature | Issuer’s signature of `SHA256(cardId | issuerData)` or or `SHA256(cardId | issuerData | issuerDataCounter)` with `Issuer_Data_PrivateKey` |
| issuerDataCounter | An optional counter that protect issuer data against replay attack. When flag Protect_Issuer_Data_Against_Replay set in the card configuration then this value is mandatory and must increase on each execution of `writeIssuerData` command.  |

##### Read issuer data
Method `tangemSdk.readIssuerData(cardId: cardId)` returns 512-byte Issuer_Data field and its issuer’s signature.

##### Read issuer extra data
Method `tangemSdk.readIssuerExtraData(cardId: cardId)` ruturns Issuer_Extra_Data field.

#### User data
##### Write user data
Method `tangemSdk.writeUserData(cardId: cardId, userData: userData, userCounter: userCounter)` write some of User_Data and User_Counter fields.
User_Data is never changed or parsed by the executable code the Tangem COS. The App defines purpose of use, format and it's payload. For example, this field may contain cashed information from blockchain to accelerate preparing new transaction.

| Parameter | Description |
| ------------ | ------------ |
| cardId | *(Optional)* If cardId is passed, the sign command will be performed only if the card  |
| User_Data | User data |
| User_Counter | Counters, that initial values can be set by App and increased on every signing of new transaction (on SIGN command that calculate new signatures). The App defines purpose of use. For example, this fields may contain blockchain nonce value. |

##### Read user data
Method tangemSdk.readUserData(cardId: cardId) returns User Data


### Advanced usage
Sometimes it's needed to perform some sequence of commands during one session. 
For instance, you need to sign some hashes, send transaction, and then put some data to a card.

#### Starting custom session
`tangemSdk.startSession(...)` starts custom session.

**Arguments:**

| Parameter | Description |
| ------------ | ------------ |
| cardId | *(Optional)* If cardId is passed, user will be asked to tap the particular card |
| initialMessage | *(Optional)* Custom text to show to user before he tapped the card |
| onSessionStarted | `@escaping (CardSession, SessionError?) -> Void` Closure that will be called after card is connected |

Closure `onSessionStarted` runs with two parameters: `CardSession` and `SessionError`. If starting session is failed, there will be `SessionError`. You need to check it first to proceed with the other commands.
After you finish with everything, close the session by calling `session.stop()` for success result or `session.stop(error: error)` for failure.

```swift
tangemSdk.startSession(cardId: nil) { session, error in
    //If session started wiithour errors
    if let error = error {
        DispatchQueue.main.async {
            //Handle error here
        }
        return
    }
    
    let readCommand = ReadCommand()
    readCommand!.run(in: session, completion: { result in
        switch result {
        case .success(let card):
            // Switch to UI thread manually
            DispatchQueue.main.async { 
                self.log(response1)
            }
            let checkWalletCommand = CheckWalletCommand(...)
            //WHY-! ?
            checkWalletCommand!.run(in: session, completion: { result in
                switch result {
                case .success(let checkWalletResult):
                    DispatchQueue.main.async {
                        self.log(checkWalletResult)
                    }
                    // Close session manually
                    session.stop() 
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


## Customization
### UI
Tangem SDK performs the entire cycle of UI user interaction. In order to change the appearance or behavior of the UI, you are welcome provide you own implementation of the `SessionViewDelegate` protocol. After this, initialize the `TangemSdk` class with your delegate class.

```swift
let mySessionViewDelegate = MySessionViewDelegate()
let tangemSdk = TangemSdk(viewDelegate: myCardManagerDelegate)
```

### Localization
You can replace one or more lines used in the SDK with your own. For this, you need to add keys with translations of the lines that you want to replace in your app, after which you need to install the localization bundle like this:
```swift
TangemSdk.Localization.localizationsBundle = Bundle(for: AppDelegate.self)
````
