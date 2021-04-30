
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
    - [Sign hash](#sign-hash)
    - [Sign hashes](#sign-hashes)
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

For any file in which you'd like to use the Tangem SDK use `import TangemSdk`.

## Usage

Tangem SDK is a self-sufficient solution that implements a card abstraction model, methods of interaction with the card and interactions with the user via UI.

### Initialization
To get started, you need to create an instance of the `TangemSdk` class. 

```swift
let sdk = TangemSdk()
```

The universal initializer allows you to create an instance of the class that you can use immediately without any additional setup. 

You can also use a custom initializer, which allows you to pass your implementation of `CardReader` protocol to communicate with a card as well as the implementation of `SessionViewDelegate` protocol to create a custom user interface.
You can read more about this in [Customization](#сustomization).

### Basic usage
The easiest way to use the SDK is to call basic functions that implemented in `TangemSdk` class. Functions performs one or more commands and, after that, calls completion block with success or error result.

Most functions have an optional `cardId` argument. If it has been passed, the command can only be executed with a card that has a matching `cardId`. If the user uses a card with a different `cardId`, the SDK will ask the user to attach the correct card with the same `cardId`.

When calling basic methods, there is no need to show the error to the user, since it will be displayed on the NFC popup before it's hidden.

**IMPORTANT**: You can't perform more than one basic function during the NFC session. In case you need to perform your own sequence of commands, take a look at [Advanced usage](#advanced-usage)

#### Common 

`CompletionResult<T>` - `typealias` of `(Result<T, TangemSdkError>) -> Void`

#### Scan card 
Method `scanCard()` is used to obtain information from the Tangem card. Optionally, if the card contains a wallet (private and public key pair), it proves that the wallet owns a private key that corresponds to a public one.

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

#### Sign hash
Method `sign(hash: Data, walletPublicKey: Data, cardId: String?)` allows you to sign a single hash with a wallet that has specified `walletPublicKey`. The SIGN command will return a corresponding signature. If card failed to find wallet with target `walletPublicKey` SDK will return `WalletNotFound` error

**Arguments:**

| Parameter | Type | Description |
| ------------ | ------ | ------------ |
| hash | `Data` | Hash to be signed by card |
| walletPublicKey | `Data` | Public key of wallet that should sign hash |
| cardId | `String?` | *(Optional)* If cardId is passed, the sign command will be performed only if the card  |
| completion | `CompletionResult<Data>` | *(@escaping)* Returns signature of `hash`


Example:
```swift
// Creates random hash with length = 32
let hash = Data((0..<32).map { _ in UInt8(arc4random_uniform(255)) })
let cardId = "AA00000000000000"
let walletPublicKey = Data()

tangemSdk.sign(hash: hash, walletPublicKey: walletPublicKey, cardId: cardId) { result in
    switch result {
    case .success(let signResponse):
        print("Result: \(signResponse)")
    case .failure(let error):
        print("Completed with error: \(error.localizedDescription)")
    }
}
```

#### Sign hashes
Method `sign(hashes: [Data], walletPublicKey: Data, cardId: String)` allows you to sign multiple hashes. The SIGN command will return a corresponding array of signatures. If card failed to find wallet with target `walletPublicKey` SDK will return `WalletNotFound` error

**Arguments:**

| Parameter | Type | Description |
| ------------ | ------ | ------------ |
| hashes | `[Data] `| Array of hashes to be signed by card |
| walletPublicKey | `Data` | Public key of wallet that should sign hashes |
| cardId | `String?` |*(Optional)* If cardId is passed, the sign command will be performed only if the card  |
| completion | `CompletionResult<[Data]>` | *(@escaping)* Returns array of signatures` |

Example:
```swift
let hashes = [hash1, hash2]
let cardId = "AA00000000000000"
let walletPublicKey = Data()

tangemSdk.sign(hashes: hashes, walletPublicKey: walletPublickey, cardId: cardId) { result in
    switch result {
    case .success(let signResponse):
        print("Result: \(signResponse)")
    case .failure(let error):
        print("Completed with error: \(error.localizedDescription)")
    }
}
```

#### Wallet
##### Create Wallet
Method `tangemSdk.createWallet(cardId: String?)` will create a new wallet on the card. A key pair `WalletPublicKey` / `WalletPrivateKey` is generated and securely stored in the card.

**Arguments:**

| Parameter | Type | Description |
| ------------ | ------ | ------------ |
| config | `WalletConfig?`| *(Optional)* Configuration of new wallet. **Note** Available only for cards with firmware version 4 and higher |
| cardId | `String?` |*(Optional)* If cardId is passed, the sign command will be performed only if the card  |
| completion | `CompletionResult<CreateWalletResponse>` | *(@escaping)* Returns information about new wallet |

##### Purge Wallet
Method `tangemSdk.purgeWallet(walletPublicKey: Data, cardId: String?)` searching wallet with specified `WalletPublicKey` and deletes all information related to this wallet.

**Arguments:**

| Parameter | Type | Description |
| ------------ | ------ | ------------ |
| walletPublicKey | `Data`| Public key of wallet that should be purged |
| cardId | `String?` |*(Optional)* If cardId is passed, the sign command will be performed only if the card  |
| completion | `CompletionResult<PurgeWalletResponse>` | *(@escaping)* Returns information about purged wallet |

#### Issuer data
Card has a special 512-byte memory block to securely store and update information in card OS (COS). For example, this mechanism could be employed for enabling off-line validation of the wallet balance and attesting of cards by the issuer (in addition to Tangem’s attestation). The issuer should define the purpose of use, payload, and format of `IssuerData` field. Note that `IssuerData` is never changed or parsed by the executable code the Tangem COS. 

The issuer has to generate single Issuer Data Key pair `IssuerDataPublicKey` / `IssuerDataPrivateKey`, same for all issuer’s cards. The private key `IssuerDataPrivateKey` is permanently stored in a secure back-end of the issuer (e.g. HSM). The non-secret public key `IssuerDataPublicKey` is stored both in COS (during personalization) and issuer’s host application that will use it to validate `IssuerData` field.

##### Write issuer data
Method `tangemSdk.writeIssuerData(issuerData: Data, issuerDataSignature: Data, issuerDataCounter: Int?, cardId: String?)` writes 512-byte `IssuerData` field to the card.

**Arguments:**

| Parameter | Type | Description |
| ------------ | ------ | ------------ |
| issuerData | `Data` | Data to be written to the card |
| issuerDataSignature | `Data` | Issuer’s signature of issuerData with `Issuer_Data_PrivateKey` |
| issuerDataCounter | `Int?` | *(Optional)* Counter that protect issuer data against replay attack. When flag `ProtectIssuerDataAgainstReplay` set in the card configuration then this value is mandatory and must increase on each execution of `writeIssuerData` command.  |
| cardId | `String?` | *(Optional)* If cardId is passed, the sign command will be performed only if the card  |

##### Write issuer extra data
If 512 bytes are not enough, you can use method `tangemSdk.writeIssuerExtraData(issuerData: Data, startingSignature: Data, finalizingSignature: Data,issuerDataCounter: Int?, cardId: String?)` to save up to 40 kylobytes.

| Parameter | Type | Description |
| ------------ | ------ | ------------ |
| issuerData | `Data` | Data to be written to the card |
| startingSignature | `Data` | Issuer’s signature of `SHA256(cardId | Size)` or `SHA256(cardId | Size | issuerDataCounter)` with `IssuerDataPrivateKey` |
| finalizingSignature | `Data` | Issuer’s signature of `SHA256(cardId | issuerData)` or or `SHA256(cardId | issuerData | issuerDataCounter)` with `IssuerDataPrivateKey` |
| issuerDataCounter | `Int?` | *(Optional)* Counter that protect issuer data against replay attack. When flag `ProtectIssuerDataAgainstReplay` set in the card configuration then this value is mandatory and must increase on each execution of `writeIssuerData` command.  |
| cardId | `String?` | *(Optional)* If cardId is passed, the sign command will be performed only if the card  |

##### Read issuer data
Method `tangemSdk.readIssuerData(cardId: cardId)` returns 512-byte `IssuerData` field and its issuer’s signature.

##### Read issuer extra data
Method `tangemSdk.readIssuerExtraData(cardId: cardId)` ruturns `IssuerExtraData` field.

#### User data
##### Write user data
Method `tangemSdk.writeUserData(userData: Data, userCounter: Int?, cardId: String?)` write some of `UserData` and `UserCounter` fields.
`UserData` is never changed or parsed by the executable code the Tangem COS. The App defines purpose of use, format and it's payload. For example, this field may contain cashed information from blockchain to accelerate preparing new transaction.

| Parameter | Type | Description |
| ------------ | ------ | ------------ |
| userData | `Data` | Data defined by user’s App |
| userCounter | `Int?` | *(Optional)* Counters, that initial values can be set by App and increased on every signing of new transaction (on SIGN command that calculate new signatures). The App defines purpose of use. For example, this fields may contain blockchain nonce value. |
| cardId | `String?` | *(Optional)* If cardId is passed, the sign command will be performed only if the card  |

##### Read user data
Method `tangemSdk.readUserData(cardId: String?)` returns User Data

### Advanced usage
Sometimes it's needed to perform some sequence of commands during one session. 
For instance, you need to sign some hashes, send transaction, and then put some data to a card.

#### Starting custom session
`tangemSdk.startSession(...)` starts custom session.

**Arguments:**

| Parameter |Type | Description |
| ------------ | ------------ | ------------ |
| cardId | `String?` | *(Optional)* If cardId is passed, user will be asked to tap the particular card |
| callback | `(CardSession, TangemSdkError?) -> Void` | *(@escaping)*  Closure that will be called after card is connected 

Closure `callback` contain two parameters: `CardSession` and `TangemSdkError`. If session is failed to start, there will be `TangemSdkError`. You need to check it first to proceed with the other commands.
After you finish with everything, close the session by calling `session.stop()` for success result or `session.stop(error: error)` for failure.

```swift
let tangemSdk = TangemSdk()

tangemSdk.startSession(cardId: nil) { session, error in
    // Logs messages on main thread
    func log(_ message: Any) {
        DispatchQueue.main.async {
            // You can put here all your logging logic
            print(message)
        }
    }
    
    // Check if error occured while starting session
    if let error = error {
        log(error)
        return
    }
    
    // Log error and stop session
    func logErrorAndStop(_ error: Error) {
        log(error)
        session.stop(error: error)
    }
    
    func signHash(walletPublicKey: Data) {
        // Creates random data for signing
        let hash = Data((0..<32).map { _ in UInt8(arc4random_uniform(255)) })
        let sign = SignCommand(hashes: [hash], walletIndex: .publicKey(walletPublicKey))
        sign.run(in: session) { signResult in
            switch signResult {
            case .success(let response):
                // Log successful SignCommand and stop session
                log("Step 3 result. Sign hash response: \(response)")
                session.stop()
            case .failure(let error):
                logErrorAndStop(error)
            }
        }
    }
    
    log("Step 1 result. Read card: \(session.environment.card)")
    // If wallet created perform CheckWalletCommand
    if let wallet = session.environment.card?.wallets.first, wallet.status == .loaded, let curve = wallet.curve, let pubkey = wallet.publicKey {
        let checkWallet = CheckWalletCommand(curve: curve, publicKey: pubkey)
        checkWallet.run(in: session) { result in
            switch result {
            case .success(let checkWalletResponse):
                log("Step 2 result. Check wallet response: \(checkWalletResponse)")
                signHash(walletPublicKey: pubkey)
            case .failure(let error):
                logErrorAndStop(error)
            }
        }
    // If there wallet at first index is empty - create wallet
    } else {
        let createWallet = CreateWalletTask(config: WalletConfig(curveId: .secp256k1))
        createWallet.run(in: session) { createWalletResult in
            switch createWalletResult {
            case .success(let createWalletResponse):
                log("Step 2 result. Create wallet response: \(createWalletResponse)")
                signHash(walletPublicKey: createWalletResponse.walletPublicKey)
            case .failure(let error):
                logErrorAndStop(error)
            }
        }
    }
}
```


## Customization
### UI
Tangem SDK performs the entire cycle of UI user interaction. In order to change the appearance or behavior of the UI, you are welcome to provide you own implementation of the `SessionViewDelegate` protocol. After this, initialize the `TangemSdk` class with your delegate class.

```swift
let mySessionViewDelegate = MySessionViewDelegate()
let tangemSdk = TangemSdk(viewDelegate: mySessionViewDelegate)
```

### Localization
You can replace one or more lines used in the SDK with your own. For this, you need to add keys with translations of the lines that you want to replace in your app, after which you need to install the localization bundle like this:
```swift
TangemSdk.Localization.localizationsBundle = Bundle(for: AppDelegate.self)
````
