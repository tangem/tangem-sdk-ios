//
//  CardManager.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC
import Combine

/// The main interface of Tangem SDK that allows your app to communicate with Tangem cards.
public final class TangemSdk {
    /// Check if the current device doesn't support the desired NFC operations
    public static var isNFCAvailable: Bool {
        if NSClassFromString("NFCNDEFReaderSession") == nil { return false }
        return NFCNDEFReaderSession.readingAvailable
    }
    
    /// Configuration of the SDK. Do not change the default values unless you know what you are doing
    public var config = Config()
    private let reader: CardReader
    private let viewDelegate: SessionViewDelegate
    private let secureStorageService = SecureStorageService()
    private let onlineCardVerifier = OnlineCardVerifier()
    private var cardSession: CardSession? = nil
    private var onlineVerificationCancellable: AnyCancellable? = nil
    private lazy var terminalKeysService: TerminalKeysService = {
        let service = TerminalKeysService(secureStorageService: secureStorageService)
        return service
    }()
    
    /// Default initializer
    /// - Parameters:
    ///   - cardReader: An interface that is responsible for NFC connection and transfer of data to and from the Tangem Card.
    ///   If nil, its default implementation will be used
    ///   - viewDelegate:  An interface that allows interaction with users and shows relevant UI.
    ///   If nil, its default implementation will be used
    ///   - config: Allows to change a number of parameters for communication with Tangem cards.
    ///   Do not change the default values unless you know what you are doing.
    public init(cardReader: CardReader? = nil, viewDelegate: SessionViewDelegate? = nil, config: Config = Config()) {
        let reader = cardReader ?? NFCReader()
        self.reader = reader
        self.viewDelegate = viewDelegate ?? DefaultSessionViewDelegate(reader: reader, config: config)
        self.config = config
    }
    
    /// To start using any card, you first need to read it using the `scanCard()` method.
    /// This method launches an NFC session, and once it’s connected with the card,
    /// it obtains the card data. Optionally, if the card contains a wallet (private and public key pair),
    /// it proves that the wallet owns a private key that corresponds to a public one.
    ///
    /// - Note: `WalletIndex` available for cards with COS v.4.0 or higher
    /// - Parameters:
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<Card,TangemSdkError>`
    public func scanCard(initialMessage: Message? = nil,
                         completion: @escaping CompletionResult<Card>) {
        startSession(with: ScanTask(), cardId: nil, initialMessage: initialMessage) { result in
            switch result {
            case .success(let response):
                if response.firmwareVersion?.type == .release,
                   let cid = response.cardId,
                   let cardPublicKey = response.cardPublicKey {
                    self.loadCardInfo(cardId: cid, cardPublicKey: cardPublicKey) { onlineVerifyResult in
                        switch onlineVerifyResult {
                        case .success:
                            completion(.success(response))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                } else {
                    completion(.success(response))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// This method allows you to sign one hash and will return a corresponding signature.
    /// Please note that Tangem cards usually protect the signing with a security delay
    /// that may last up to 45 seconds, depending on a card.
    /// It is for `SessionViewDelegate` to notify users of security delay.
    ///
    /// - Note: `WalletIndex` available for cards with COS v.4.0 and higher
    /// - Parameters:
    ///   - cardId: CID, Unique Tangem card ID number
    ///   - hash: Transaction hash for sign by card.
    ///   - walletPublicKey: Public key of wallet that should sign hash.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns  `Swift.Result<SignResponse,TangemSdkError>`
    public func sign(cardId: String? = nil,
                     hash: Data,
                     walletPublicKey: Data,
                     initialMessage: Message? = nil,
                     completion: @escaping CompletionResult<Data>) {
        sign(cardId: cardId, hashes: [hash], walletPublicKey: walletPublicKey, initialMessage: initialMessage) { (result) in
            switch result {
            case .success(let signatures):
                guard signatures.count == 1 else {
                    completion(.failure(.notValidSignedSignatureSize))
                    return
                }
                
                completion(.success(signatures[0]))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// This method allows you to sign one or multiple hashes.
    /// Simultaneous signing of array of hashes in a single `SignCommand` is required to support
    /// Bitcoin-type multi-input blockchains (UTXO).
    /// The `SignCommand` will return a corresponding array of signatures.
    /// Please note that Tangem cards usually protect the signing with a security delay
    /// that may last up to 45 seconds, depending on a card.
    /// It is for `SessionViewDelegate` to notify users of security delay.
    ///
    /// - Note: `WalletIndex` available for cards with COS v.4.0 and higher
    /// - Parameters:
    ///   - cardId: CID, Unique Tangem card ID number
    ///   - hashes: Array of transaction hashes. It can be from one or up to ten hashes of the same length.
    ///   - walletPublicKey: Public key of wallet that should sign hashes.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns  `Swift.Result<SignResponse,TangemSdkError>`
    public func sign(cardId: String? = nil,
                     hashes: [Data],
                     walletPublicKey: Data,
                     initialMessage: Message? = nil,
                     completion: @escaping CompletionResult<[Data]>) {
        startSession(with: SignCommand(hashes: hashes, walletIndex: .publicKey(walletPublicKey))) { (result) in
            switch result {
            case .success(let response):
                completion(.success(response.signatures))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// This command will create a new wallet on the card having ‘Empty’ state.
    /// A key pair WalletPublicKey / WalletPrivateKey is generated and securely stored in the card.
    /// App will need to obtain Wallet_PublicKey from the response of `CreateWalletCommand` or `ReadCommand`
    /// and then transform it into an address of corresponding blockchain wallet
    /// according to a specific blockchain algorithm.
    /// WalletPrivateKey is never revealed by the card and will be used by `SignCommand` and `CheckWalletCommand`.
    /// RemainingSignature is set to MaxSignatures.
    ///
    /// - Note: `WalletConfig` available for cards with COS v.4.0 or higher
    /// - Parameters:
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - config: Configuration for wallet that should be created (blockchain name, token...). This parameter available for cards with COS v.4.0 and higher. For earlier versions it will be ignored
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<CreateWalletResponse,TangemSdkError>`
    public func createWallet(cardId: String? = nil,
                             config: WalletConfig? = nil,
                             initialMessage: Message? = nil,
                             completion: @escaping CompletionResult<CreateWalletResponse>) {
        let task = CreateWalletTask(config: config)
        startSession(with: task, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /// This command deletes all wallet data. If Is_Reusable flag is enabled during personalization,
    /// the card changes state to ‘Empty’ and a new wallet can be created by `CREATE_WALLET` command.
    /// If Is_Reusable flag is disabled, the card switches to ‘Purged’ state.
    /// ‘Purged’ state is final, it makes the card useless.
    ///
    /// - Note: Wallet index available for cards with COS v.4.0 or higher
    /// - Parameters:
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - walletPublicKey: Public key of wallet that should be purged.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<PurgeWalletResponse,TangemSdkError>`
    public func purgeWallet(cardId: String? = nil,
                            walletPublicKey: Data,
                            initialMessage: Message? = nil,
                            completion: @escaping CompletionResult<PurgeWalletResponse>) {
        startSession(with: PurgeWalletCommand(walletIndex: .publicKey(walletPublicKey)), cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /**
     * This command returns 512-byte Issuer Data field and its issuer’s signature.
     * Issuer Data is never changed or parsed from within the Tangem COS. The issuer defines purpose of use,
     * format and payload of Issuer Data. For example, this field may contain information about
     * wallet balance signed by the issuer or additional issuer’s attestation data.
     * - Parameters:
     *   - cardId: CID, Unique Tangem card ID number.
     *   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
     *   - completion: Returns `Swift.Result<ReadIssuerDataResponse,TangemSdkError>`
     */
    public func readIssuerData(cardId: String? = nil,
                               initialMessage: Message? = nil,
                               completion: @escaping CompletionResult<ReadIssuerDataResponse>) {
        startSession(with: ReadIssuerDataCommand(issuerPublicKey: config.issuerPublicKey),
                     cardId: cardId,
                     initialMessage: initialMessage,
                     completion: completion)
    }
    
    /**
     * This command writes 512-byte Issuer Data field and its issuer’s signature.
     * Issuer Data is never changed or parsed from within the Tangem COS. The issuer defines purpose of use,
     * format and payload of Issuer Data. For example, this field may contain information about
     * wallet balance signed by the issuer or additional issuer’s attestation data.
     * - Parameters:
     *   - cardId:  CID, Unique Tangem card ID number.
     *   - issuerData: Data provided by issuer.
     *   - issuerDataSignature: Issuer’s signature of `issuerData` with Issuer Data Private Key (which is kept on card).
     *   - issuerDataCounter: An optional counter that protect issuer data against replay attack.
     *   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
     *   - completion: Returns `Swift.Result<WriteIssuerDataResponse,TangemSdkError>`
     */
    public func writeIssuerData(cardId: String? = nil,
                                issuerData: Data,
                                issuerDataSignature: Data,
                                issuerDataCounter: Int? = nil,
                                initialMessage: Message? = nil,
                                completion: @escaping CompletionResult<WriteIssuerDataResponse>) {
        let command = WriteIssuerDataCommand(issuerData: issuerData,
                                             issuerDataSignature: issuerDataSignature,
                                             issuerDataCounter: issuerDataCounter,
                                             issuerPublicKey: config.issuerPublicKey)
        startSession(with: command, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    
    /// This task retrieves Issuer Extra Data field and its issuer’s signature.
    /// Issuer Extra Data is never changed or parsed from within the Tangem COS. The issuer defines purpose of use,
    /// format and payload of Issuer Data. . For example, this field may contain photo or
    /// biometric information for ID card product. Because of the large size of Issuer_Extra_Data,
    /// a series of these commands have to be executed to read the entire Issuer_Extra_Data.
    ///
    /// - Warning: This command is not supported for COS 3.29 and higher. Use files api instead
    /// - Parameters:
    ///   - cardId:  CID, Unique Tangem card ID number.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<ReadIssuerExtraDataResponse,TangemSdkError>`
    public func readIssuerExtraData(cardId: String? = nil,
                                    initialMessage: Message? = nil,
                                    completion: @escaping CompletionResult<ReadIssuerExtraDataResponse>) {
        let command = ReadIssuerExtraDataCommand(issuerPublicKey: config.issuerPublicKey)
        startSession(with: command, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /// This task writes Issuer Extra Data field and its issuer’s signature.
    /// Issuer Extra Data is never changed or parsed from within the Tangem COS.
    /// The issuer defines purpose of use, format and payload of Issuer Data.
    /// For example, this field may contain a photo or biometric information for ID card products.
    /// Because of the large size of Issuer_Extra_Data, a series of these commands have to be executed
    /// to write entire Issuer_Extra_Data.
    ///
    /// - Warning: This command is not supported for COS 3.29 and higher. Use files api instead
    /// - Parameters:
    ///   - cardId:  CID, Unique Tangem card ID number.
    ///   - issuerData: Data provided by issuer.
    ///   - startingSignature: Issuer’s signature with Issuer Data Private Key of [cardId],
    ///   [issuerDataCounter] (if flags Protect_Issuer_Data_Against_Replay and
    ///   Restrict_Overwrite_Issuer_Extra_Data are set in [SettingsMask]) and size of [issuerData].
    ///   - finalizingSignature:  Issuer’s signature with Issuer Data Private Key of [cardId],
    ///   [issuerData] and [issuerDataCounter] (the latter one only if flags Protect_Issuer_Data_Against_Replay
    ///   and Restrict_Overwrite_Issuer_Extra_Data are set in [SettingsMask]).
    ///   - issuerDataCounter:  An optional counter that protect issuer data against replay attack.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<WriteIssuerDataResponse,TangemSdkError>`
    public func writeIssuerExtraData(cardId: String? = nil,
                                     issuerData: Data,
                                     startingSignature: Data,
                                     finalizingSignature: Data,
                                     issuerDataCounter: Int? = nil,
                                     initialMessage: Message? = nil,
                                     completion: @escaping CompletionResult<WriteIssuerDataResponse>) {
        
        let command = WriteIssuerExtraDataCommand(issuerData: issuerData,
                                                  issuerPublicKey: config.issuerPublicKey,
                                                  startingSignature: startingSignature,
                                                  finalizingSignature: finalizingSignature,
                                                  issuerDataCounter: issuerDataCounter)
        
        startSession(with: command, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /**
     * This method launches a [ReadUserDataCommand]
     *
     * This command returns two up to 512-byte User_Data, User_Protected_Data and two counters User_Counter and
     * User_Protected_Counter fields.
     * User_Data and User_ProtectedData are never changed or parsed by the executable code the Tangem COS.
     * The App defines purpose of use, format and it's payload. For example, this field may contain cashed information
     * from blockchain to accelerate preparing new transaction.
     * User_Counter and User_ProtectedCounter are counters, that initial values can be set by App and increased on every signing
     * of new transaction (on SIGN command that calculate new signatures). The App defines purpose of use.
     * For example, this fields may contain blockchain nonce value.
     *
     * - Parameters:
     *   - cardId:  CID, Unique Tangem card ID number.
     *   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
     *   - completion: Returns `Swift.Result<ReadUserDataResponse,TangemSdkError>`
     */
    public func readUserData(cardId: String? = nil,
                             initialMessage: Message? = nil,
                             completion: @escaping CompletionResult<ReadUserDataResponse>) {
        startSession(with: ReadUserDataCommand(), cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /**
     * This method launches a [WriteUserDataCommand]
     *
     * This command writes some UserData, and UserCounter fields.
     * User_Data are never changed or parsed by the executable code the Tangem COS.
     * The App defines purpose of use, format and it's payload. For example, this field may contain cashed information
     * from blockchain to accelerate preparing new transaction.
     * User_Counter are counter, that initial value can be set by App and increased on every signing
     * of new transaction (on SIGN command that calculate new signatures). The App defines purpose of use.
     * For example, this fields may contain blockchain nonce value.
     *
     * Writing of UserCounter and UserData is protected only by PIN1.
     * - Parameters:
     *   - cardId:  CID, Unique Tangem card ID number.
     *   - userData: Data defined by user’s App
     *   - userCounter: Counter initialized by user’s App and increased on every signing of new transaction.  If nil, the current counter value will not be overwritten.
     *   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
     *   - completion: Returns `Swift.Result<WriteUserDataResponse,TangemSdkError>`
     */
    public func writeUserData(cardId: String? = nil,
                              userData: Data,
                              userCounter: Int? = nil,
                              initialMessage: Message? = nil,
                              completion: @escaping CompletionResult<WriteUserDataResponse>) {
        let writeUserDataCommand = WriteUserDataCommand(userData: userData, userCounter: userCounter)
        startSession(with: writeUserDataCommand, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /**
     * This method launches a [WriteUserDataCommand]
     *
     * This command writes some UserProtectedData and UserProtectedCounter fields.
     * User_ProtectedData are never changed or parsed by the executable code the Tangem COS.
     * The App defines purpose of use, format and it's payload. For example, this field may contain cashed information
     * from blockchain to accelerate preparing new transaction.
     * User_ProtectedCounter are counter, that initial value can be set by App and increased on every signing
     * of new transaction (on SIGN command that calculate new signatures). The App defines purpose of use.
     * For example, this fields may contain blockchain nonce value.
     *
     * UserProtectedCounter and UserProtectedData is protected by PIN1 and need additionally PIN2 to confirmation.
     * - Parameters:
     *   - cardId:  CID, Unique Tangem card ID number.
     *   - userProtectedData: Data defined by user’s App (confirmed by PIN2)
     *   - userProtectedCounter: Counter initialized by user’s App (confirmed by PIN2) and increased on every signing of new transaction.  If nil, the current counter value will not be overwritten.
     *   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
     *   - completion: Returns `Swift.Result<WriteUserDataResponse,TangemSdkError>`
     */
    public func writeUserProtectedData(cardId: String? = nil,
                                       userProtectedData: Data,
                                       userProtectedCounter: Int? = nil,
                                       initialMessage: Message? = nil,
                                       completion: @escaping CompletionResult<WriteUserDataResponse>) {
        let writeUserDataCommand = WriteUserDataCommand(userProtectedData: userProtectedData, userProtectedCounter: userProtectedCounter)
        startSession(with: writeUserDataCommand, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /**
     * This method launches a [VerifyCardCommand] on a new thread.
     *
     * The command to ensures the card has not been counterfeited.
     * By using standard challenge-response scheme, the card proves possession of CardPrivateKey
     * that corresponds to CardPublicKey returned by [ReadCommand]. Then the data is sent
     * to Tangem server to prove that  this card was indeed issued by Tangem.
     * The online part of the verification is unavailable for DevKit cards.
     *
     *
     * @param cardId CID, Unique Tangem card ID number.
     * @param online flag that allows disable online verification. Do not use for developer cards
     * @param callback is triggered on the completion of the [VerifyCardCommand] and provides
     * card response in the form of [VerifyCardResponse] if the task was performed successfully
     * or [TangemSdkError] in case of an error.
     */
    public func verify(cardId: String? = nil,
                       online: Bool = true,
                       initialMessage: Message? = nil,
                       completion: @escaping CompletionResult<VerifyCardResponse>) {
        startSession(with: VerifyCardCommand(), cardId: cardId, initialMessage: initialMessage) { result in
            switch result {
            case .success(let response):
                if online {
                    self.loadCardInfo(cardId: response.cardId, cardPublicKey: response.cardPublicKey) { onlineVerifyResult in
                        switch onlineVerifyResult {
                        case .success(let onlineVerifyResponse):
                            let response = VerifyCardResponse(cardId: response.cardId,
                                                              salt: response.salt,
                                                              cardSignature: response.cardSignature,
                                                              cardPublicKey: response.cardPublicKey,
                                                              verificationState: .online,
                                                              artworkInfo: onlineVerifyResponse.artwork)
                            completion(.success(response))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                } else {
                    completion(.success(response))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get the card info and verify with Tangem backend. Do not use for developer cards
    /// - Parameters:
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - cardPublicKey: CardPublicKey returned by [ReadCommand]
    ///   - completion: `CardVerifyAndGetInfoResponse.Item`
    public func loadCardInfo(cardId: String,
                            cardPublicKey: Data,
                            completion: @escaping CompletionResult<CardVerifyAndGetInfoResponse.Item>) {
        onlineVerificationCancellable = onlineCardVerifier
            .getCardInfo(cardId: cardId, cardPublicKey: cardPublicKey)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { receivedCompletion in
                if case let .failure(error) = receivedCompletion {
                    completion(.failure(error.toTangemSdkError()))
                }
            }, receiveValue: { response in
                completion(.success(response))
            })
    }
    
    /// Command available on SDK cards only
    ///  Personalization is an initialization procedure, required before starting using a card.
    /// During this procedure a card setting is set up. During this procedure all data exchange is encrypted.
    /// - Warning: Command available only for cards with COS 3.34 and higher
    /// - Parameters:
    ///   - config: is a configuration file with all the card settings that are written on the card during personalization.
    ///   - issuer: Issuer is a third-party team or company wishing to use Tangem cards.
    ///   - manufacturer: Tangem Card Manufacturer.
    ///   - acquirer: Acquirer is a trusted third-party company that operates proprietary
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   (non-EMV) POS terminal infrastructure and transaction processing back-end.
    ///   - completion: Returns `Swift.Result<Card,TangemSdkError>`
    public func personalize(config: CardConfig,
                            issuer: Issuer,
                            manufacturer: Manufacturer,
                            acquirer: Acquirer? = nil,
                            initialMessage: Message? = nil,
                            completion: @escaping CompletionResult<Card>) {
        let command = PersonalizeCommand(config: config, issuer: issuer, manufacturer: manufacturer, acquirer: acquirer)
        startSession(with: command, initialMessage: initialMessage, completion: completion)
    }
    
    /// Command available on SDK cards only
    /// This command resets card to initial state, erasing all data written during personalization and usage.
    /// - Parameters:
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<DepersonalizeResponse,TangemSdkError>`
    public func depersonalize(initialMessage: Message? = nil, completion: @escaping CompletionResult<DepersonalizeResponse>) {
        startSession(with: DepersonalizeCommand(), cardId: nil, initialMessage: initialMessage, completion: completion)
    }
    
    public func changePin1(cardId: String? = nil,
                           pin: Data? = nil,
                           initialMessage: Message? = nil,
                           completion: @escaping CompletionResult<SetPinResponse>){
        let command = SetPinCommand(pinType: .pin1, pin: pin)
        startSession(with: command, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    public func changePin2(cardId: String? = nil,
                           pin: Data? = nil,
                           initialMessage: Message? = nil,
                           completion: @escaping CompletionResult<SetPinResponse>){
        let command = SetPinCommand(pinType: .pin2, pin: pin)
        startSession(with: command, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /// This command reads all files stored on card.
    ///
    /// By default command trying to read all files (including private), to change this behaviour - setup your ` ReadFileDataTaskSetting `
    /// - Note: When performing reading private files command, you must  provide `pin2`
    /// - Warning: Command available only for cards with COS 3.29 and higher
    /// - Parameters:
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - readPrivateFiles: If true - all files saved on card will be read otherwise
    ///   - indicies: Indicies of files that should be read from card. If not specifies all files will be read.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<ReadFilesResponse,TangemSdkError>`
    public func readFiles(cardId: String? = nil,
                          readPrivateFiles: Bool = false,
                          indicies: [Int]? = nil,
                          initialMessage: Message? = nil,
                          completion: @escaping CompletionResult<ReadFilesResponse>) {
        let task = ReadFilesTask(readPrivateFiles: readPrivateFiles, indicies: indicies)
        startSession(with: task, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /// Updates selected file settings provided within `File`.
    ///
    /// To perform file settings update you should initially read all files (`readFiles` command), select files that you want to update, change their settings in `File.fileSettings` and add them to `files` array.
    /// - Note: In COS 3.29 and higher only file visibility option (public or private) available to update
    /// - Warning: This method works with COS 3.29 and higher
    /// - Parameters:
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - changes: Array of file indecies with new settings
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<SimpleResponse, TangemSdkError>`
    public func changeFilesSettings(cardId: String? = nil,
                                    changes: [FileSettingsChange],
                                    initialMessage: Message? = nil,
                                    completion: @escaping CompletionResult<SimpleResponse>) {
        let task = ChangeFilesSettingsTask(changes: changes)
        startSession(with: task, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /// This command write all files provided in `files` to card.
    ///
    /// There are 2 main implementation of `DataToWrite` protocol:
    ///  1. `FileDataProtectedBySignature` - for files  signed by Issuer (specified on card during personalization)
    ///  2. `FileDataProtectedByPasscode` - write files protected by Pin2
    /// - Warning: This command available for COS 3.29 and higher
    /// - Note: Writing files protected by Pin2 only available for COS 3.34 and higher
    /// - Parameters:
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - files: List of files that should be written to card
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<WriteFilesResponse, TangemSdkError>`
    public func writeFiles(cardId: String? = nil,
                           files: [DataToWrite],
                           initialMessage: Message? = nil,
                           completion: @escaping CompletionResult<WriteFilesResponse>) {
        let task = WriteFilesTask(files: files)
        startSession(with: task, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /// This command deletes selected files from card. This operation can't be undone.
    ///
    /// To perform file deletion you should initially read all files (`readFiles` command) and add them to `indices` array. When files deleted from card, other files change their indexies.
    /// After deleting files you should additionally perform `readFiles` command to actualize files indexes
    /// - Warning: This command available for COS 3.29 and higher
    /// - Parameters:
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - indices: Indexes of files that should be deleteled. If nil - deletes all files from card
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<SimpleResponse, TangemSdkError>`
    public func deleteFiles(cardId: String? = nil,
                            indicesToDelete indices: [Int]?,
                            initialMessage: Message? = nil,
                            completion: @escaping CompletionResult<SimpleResponse>) {
        let task = DeleteFilesTask(filesToDelete: indices)
        startSession(with: task, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /// Creates hashes and signatures for files that signed by issuer
    /// - Parameters:
    ///     - cardId: CID, Unique Tangem card ID number.
    ///     - fileData: File data that will be written on card
    ///     - fileCounter:  A counter that protects issuer data against replay attack.
    ///     - privateKey: Optional private key that will be used for signing files hashes. If it is provided, then  `FileHashData` will contain signed file signatures.
    /// - Returns:
    /// `FileHashData` with hashes to sign and signatures if `privateKey` was provided.
    public func prepareHashes(cardId: String, fileData: Data, fileCounter: Int, privateKey: Data? = nil) -> FileHashData {
        return FileHashHelper.prepareHash(for: cardId, fileData: fileData, fileCounter: fileCounter, privateKey: privateKey)
    }
    
    /// Allows running a custom bunch of commands in one NFC Session by creating a custom task. Tangem SDK will start a card session, perform preflight `Read` command,
    /// invoke the `run ` method of `CardSessionRunnable` and close the session.
    /// You can find the current card in the `environment` property of the `CardSession`
    /// - Parameters:
    ///   - runnable: A custom task, adopting `CardSessionRunnable` protocol
    ///   - cardId: CID, Unique Tangem card ID number. If not nil, the SDK will check that you tapped the  card with this cardID and will return the `wrongCard` error' otherwise
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Standart completion handler. Invoked on the main thread. `(Swift.Result<CardSessionRunnable.CommandResponse, TangemSdkError>) -> Void`.
    public func startSession<T>(with runnable: T,
                                cardId: String? = nil,
                                initialMessage: Message? = nil,
                                completion: @escaping CompletionResult<T.CommandResponse>)
    where T : CardSessionRunnable {
        
        if let existingSession = cardSession, existingSession.state == .active  {
            completion(.failure(.busy))
            return
        }
        configure()
        cardSession = CardSession(environment: buildEnvironment(),
                                  cardId: cardId,
                                  initialMessage: initialMessage,
                                  cardReader: reader,
                                  viewDelegate: viewDelegate)
        
        cardSession!.start(with: runnable, completion: completion)
    }
    
    /// Allows running  a custom bunch of commands in one NFC Session with lightweight closure syntax. Tangem SDK will start a card sesion and perform preflight `Read` command.
    /// - Parameters:
    ///   - cardId: CID, Unique Tangem card ID number. If not nil, the SDK will check that you tapped the  card with this cardID and will return the `wrongCard` error' otherwise
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - callback: At first, you should check that the `TangemSdkError` is not nil, then you can use the `CardSession` to interact with a card.
    ///   You can find the current card in the `environment` property of the `CardSession`
    ///   If you need to interact with UI, you should dispatch to the main thread manually
    public func startSession(cardId: String? = nil,
                             initialMessage: Message? = nil,
                             callback: @escaping (CardSession, TangemSdkError?) -> Void) {
        
        if let existingSession = cardSession, existingSession.state == .active  {
            callback(existingSession, .busy)
            return
        }
        configure()
        cardSession = CardSession(environment: buildEnvironment(),
                                  cardId: cardId,
                                  initialMessage: initialMessage,
                                  cardReader: reader,
                                  viewDelegate: viewDelegate)
        cardSession?.start(callback)
    }
    
    private func configure() {
        viewDelegate.setConfig(config)
        Log.config = config.logСonfig
    }
    
    private func buildEnvironment() -> SessionEnvironment{
        var environment = SessionEnvironment()
        environment.legacyMode = config.legacyMode ?? NfcUtils.isPoorNfcQualityDevice
        if config.linkedTerminal ?? !NfcUtils.isPoorNfcQualityDevice {
            environment.terminalKeys = terminalKeysService.getKeys()
        }
        environment.allowedCardTypes = config.allowedCardTypes
        environment.handleErrors = config.handleErrors
        
        return environment
    }
}
