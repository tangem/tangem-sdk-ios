//
//  ReadCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public typealias ReadResponse = Card

/// Determines which type of data is required for signing.
public struct SigningMethod: OptionSet, Codable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        if rawValue & 0x80 != 0 {
            self.rawValue = rawValue
        } else {
            self.rawValue = 0b10000000|(1 << rawValue)
        }
    }
    
    public static let signHash = SigningMethod(rawValue: 0b10000000|(1 << 0))
    public static let signRaw = SigningMethod(rawValue: 0b10000000|(1 << 1))
    public static let signHashSignedByIssuer = SigningMethod(rawValue: 0b10000000|(1 << 2))
    public static let signRawSignedByIssuer = SigningMethod(rawValue: 0b10000000|(1 << 3))
    public static let signHashSignedByIssuerAndUpdateIssuerData = SigningMethod(rawValue: 0b10000000|(1 << 4))
    public static let signRawSignedByIssuerAndUpdateIssuerData = SigningMethod(rawValue: 0b10000000|(1 << 5))
    public static let signPos = SigningMethod(rawValue: 0b10000000|(1 << 6))
    
    public func encode(to encoder: Encoder) throws {
        var values = [String]()
        if contains(SigningMethod.signHash) {
            values.append("SignHash")
        }
        if contains(SigningMethod.signRaw) {
            values.append("SignRaw")
        }
        if contains(SigningMethod.signHashSignedByIssuer) {
            values.append("SignHashSignedByIssuer")
        }
        if contains(SigningMethod.signRawSignedByIssuer) {
            values.append("SignRawSignedByIssuer")
        }
        if contains(SigningMethod.signHashSignedByIssuerAndUpdateIssuerData) {
            values.append("SignHashSignedByIssuerAndUpdateIssuerData")
        }
        if contains(SigningMethod.signRawSignedByIssuerAndUpdateIssuerData) {
            values.append("SignRawSignedByIssuerAndUpdateIssuerData")
        }
        if contains(SigningMethod.signPos) {
            values.append("SignPos")
        }
        
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        let stringValues = try values.decode([String].self)
        var mask = SigningMethod()
        
        if stringValues.contains("SignHash") {
            mask.update(with: SigningMethod.signHash)
        }
        
        if stringValues.contains("SignRaw") {
            mask.update(with: SigningMethod.signRaw)
        }
        
        if stringValues.contains("SignHashSignedByIssuer") {
            mask.update(with: SigningMethod.signHashSignedByIssuer)
        }
        
        if stringValues.contains("SignRawSignedByIssuer") {
            mask.update(with: SigningMethod.signRawSignedByIssuer)
        }
        
        if stringValues.contains("SignHashSignedByIssuerAndUpdateIssuerData") {
            mask.update(with: SigningMethod.signHashSignedByIssuerAndUpdateIssuerData)
        }
        
        if stringValues.contains("SignRawSignedByIssuerAndUpdateIssuerData") {
            mask.update(with: SigningMethod.signRawSignedByIssuerAndUpdateIssuerData)
        }
        
        if stringValues.contains("SignPos") {
            mask.update(with: SigningMethod.signPos)
        }
        
        self = mask
    }
}

/// Elliptic curve used for wallet key operations.
public enum EllipticCurve: String, Codable {
    case secp256k1
    case ed25519
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        let stringValue = try values.decode(String.self).lowercased()
        if let curve = EllipticCurve(rawValue: stringValue) {
            self = curve
        } else {
            throw TangemSdkError.decodingFailed
        }
    }
}

/// Status of the card and its wallet.
public enum CardStatus: Int, Codable {
    case notPersonalized = 0
    case empty = 1
    case loaded = 2
    case purged = 3
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(self)".capitalized)
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        let stringValue = try values.decode(String.self).lowercasingFirst()
        switch stringValue {
        case "notPersonalized":
            self = .notPersonalized
        case "empty":
            self = .empty
        case "loaded":
            self = .loaded
        case "purged":
            self = .purged
        default:
            throw TangemSdkError.decodingFailed
        }
    }
}

public struct ProductMask: OptionSet, Codable {
    public let rawValue: Byte
    
    public init(rawValue: Byte) {
        self.rawValue = rawValue
    }
    
    public static let note = ProductMask(rawValue: 0x01)
    public static let tag = ProductMask(rawValue: 0x02)
    public static let idCard = ProductMask(rawValue: 0x04)
    public static let idIssuer = ProductMask(rawValue: 0x08)
    
    public func encode(to encoder: Encoder) throws {
        var values = [String]()
        if contains(ProductMask.note) {
            values.append("Note")
        }
        if contains(ProductMask.tag) {
            values.append("Tag")
        }
        if contains(ProductMask.idCard) {
            values.append("IdCard")
        }
        if contains(ProductMask.idIssuer) {
            values.append("IdIssuer")
        }
        
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        let stringValues = try values.decode([String].self)
        var mask = ProductMask()
        
        if stringValues.contains("Note") {
            mask.update(with: ProductMask.note)
        }
        
        if stringValues.contains("Tag") {
            mask.update(with: ProductMask.tag)
        }
        
        if stringValues.contains("IdCard") {
            mask.update(with: ProductMask.idCard)
        }
        
        if stringValues.contains("IdIssuer") {
            mask.update(with: ProductMask.idIssuer)
        }
        
        self = mask
    }
}

/// Stores and maps Tangem card settings.
public struct SettingsMask: OptionSet, Codable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let isReusable = SettingsMask(rawValue: 0x0001)
    public static let useActivation = SettingsMask(rawValue: 0x0002)
    public static let prohibitPurgeWallet = SettingsMask(rawValue: 0x0004)
    public static let useBlock = SettingsMask(rawValue: 0x0008)
    public static let allowSetPIN1 = SettingsMask(rawValue: 0x0010)
    public static let allowSetPIN2 = SettingsMask(rawValue: 0x0020)
    public static let useCvc = SettingsMask(rawValue: 0x0040)
    public static let prohibitDefaultPIN1 = SettingsMask(rawValue: 0x0080)
    public static let useOneCommandAtTime = SettingsMask(rawValue: 0x0100)
    public static let useNDEF = SettingsMask(rawValue: 0x0200)
    public static let useDynamicNDEF = SettingsMask(rawValue: 0x0400)
    public static let smartSecurityDelay = SettingsMask(rawValue: 0x0800)
    public static let allowUnencrypted = SettingsMask(rawValue: 0x1000)
    public static let allowFastEncryption = SettingsMask(rawValue: 0x2000)
    public static let protectIssuerDataAgainstReplay = SettingsMask(rawValue: 0x4000)
    public static let allowSelectBlockchain = SettingsMask(rawValue: 0x8000)
    public static let disablePrecomputedNDEF = SettingsMask(rawValue: 0x00010000)
    public static let skipSecurityDelayIfValidatedByIssuer = SettingsMask(rawValue: 0x00020000)
    public static let skipCheckPIN2CVCIfValidatedByIssuer = SettingsMask(rawValue: 0x00040000)
    public static let skipSecurityDelayIfValidatedByLinkedTerminal = SettingsMask(rawValue: 0x00080000)
    public static let restrictOverwriteIssuerExtraData = SettingsMask(rawValue: 0x00100000)
    public static let requireTermTxSignature = SettingsMask(rawValue: 0x01000000)
    public static let requireTermCertSignature = SettingsMask(rawValue: 0x02000000)
    public static let checkPIN3OnCard = SettingsMask(rawValue: 0x04000000)
    
    public func encode(to encoder: Encoder) throws {
        var values = [String]()
        if contains(SettingsMask.isReusable) {
            values.append("IsReusable")
        }
        if contains(SettingsMask.useActivation) {
            values.append("UseActivation")
        }
        if contains(SettingsMask.prohibitPurgeWallet) {
            values.append("ProhibitPurgeWallet")
        }
        if contains(SettingsMask.useBlock) {
            values.append("UseBlock")
        }
        if contains(SettingsMask.allowSetPIN1) {
            values.append("AllowSetPIN1")
        }
        if contains(SettingsMask.allowSetPIN2) {
            values.append("AllowSetPIN2")
        }
        if contains(SettingsMask.useCvc) {
            values.append("UseCvc")
        }
        if contains(SettingsMask.prohibitDefaultPIN1) {
            values.append("ProhibitDefaultPIN1")
        }
        if contains(SettingsMask.useOneCommandAtTime) {
            values.append("UseOneCommandAtTime")
        }
        if contains(SettingsMask.useNDEF) {
            values.append("UseNDEF")
        }
        if contains(SettingsMask.useDynamicNDEF) {
            values.append("UseDynamicNDEF")
        }
        if contains(SettingsMask.smartSecurityDelay) {
            values.append("SmartSecurityDelay")
        }
        if contains(SettingsMask.allowUnencrypted) {
            values.append("AllowUnencrypted")
        }
        if contains(SettingsMask.allowFastEncryption) {
            values.append("AllowFastEncryption")
        }
        if contains(SettingsMask.protectIssuerDataAgainstReplay) {
            values.append("ProtectIssuerDataAgainstReplay")
        }
        if contains(SettingsMask.allowSelectBlockchain) {
            values.append("AllowSelectBlockchain")
        }
        if contains(SettingsMask.disablePrecomputedNDEF) {
            values.append("DisablePrecomputedNDEF")
        }
        if contains(SettingsMask.skipSecurityDelayIfValidatedByIssuer) {
            values.append("SkipSecurityDelayIfValidatedByIssuer")
        }
        if contains(SettingsMask.skipCheckPIN2CVCIfValidatedByIssuer) {
            values.append("SkipCheckPIN2CVCIfValidatedByIssuer")
        }
        if contains(SettingsMask.skipSecurityDelayIfValidatedByLinkedTerminal) {
            values.append("SkipSecurityDelayIfValidatedByLinkedTerminal")
        }
        if contains(SettingsMask.restrictOverwriteIssuerExtraData) {
            values.append("RestrictOverwriteIssuerExtraDara")
        }
        if contains(SettingsMask.requireTermTxSignature) {
            values.append("RequireTermTxSignature")
        }
        if contains(SettingsMask.requireTermCertSignature) {
            values.append("RequireTermCertSignature")
        }
        if contains(SettingsMask.checkPIN3OnCard) {
            values.append("CheckPIN3OnCard")
        }
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        let stringValues = try values.decode([String].self)
        var mask = SettingsMask()
        if stringValues.contains("IsReusable") {
            mask.update(with: SettingsMask.isReusable)
        }
        if stringValues.contains("UseActivation") {
            mask.update(with: SettingsMask.useActivation)
        }
        if stringValues.contains("ProhibitPurgeWallet") {
            mask.update(with: SettingsMask.prohibitPurgeWallet)
        }
        if stringValues.contains("UseBlock") {
            mask.update(with: SettingsMask.useBlock)
        }
        if stringValues.contains("AllowSetPIN1") {
            mask.update(with: SettingsMask.allowSetPIN1)
        }
        if stringValues.contains("AllowSetPIN2") {
            mask.update(with: SettingsMask.allowSetPIN2)
        }
        if stringValues.contains("UseCvc") {
            mask.update(with: SettingsMask.useCvc)
        }
        if stringValues.contains("ProhibitDefaultPIN1") {
            mask.update(with: SettingsMask.prohibitDefaultPIN1)
        }
        if stringValues.contains("UseOneCommandAtTime") {
            mask.update(with: SettingsMask.useOneCommandAtTime)
        }
        if stringValues.contains("UseNDEF") {
            mask.update(with: SettingsMask.useNDEF)
        }
        if stringValues.contains("UseDynamicNDEF") {
            mask.update(with: SettingsMask.useDynamicNDEF)
        }
        if stringValues.contains("SmartSecurityDelay") {
            mask.update(with: SettingsMask.smartSecurityDelay)
        }
        if stringValues.contains("AllowUnencrypted") {
            mask.update(with: SettingsMask.allowUnencrypted)
        }
        if stringValues.contains("AllowFastEncryption") {
            mask.update(with: SettingsMask.allowFastEncryption)
        }
        if stringValues.contains("ProtectIssuerDataAgainstReplay") {
            mask.update(with: SettingsMask.protectIssuerDataAgainstReplay)
        }
        if stringValues.contains("AllowSelectBlockchain") {
            mask.update(with: SettingsMask.allowSelectBlockchain)
        }
        if stringValues.contains("DisablePrecomputedNDEF") {
            mask.update(with: SettingsMask.disablePrecomputedNDEF)
        }
        if stringValues.contains("SkipSecurityDelayIfValidatedByIssuer") {
            mask.update(with: SettingsMask.skipSecurityDelayIfValidatedByIssuer)
        }
        if stringValues.contains("SkipCheckPIN2CVCIfValidatedByIssuer") {
            mask.update(with: SettingsMask.skipCheckPIN2CVCIfValidatedByIssuer)
        }
        if stringValues.contains("SkipSecurityDelayIfValidatedByLinkedTerminal") {
            mask.update(with: SettingsMask.skipSecurityDelayIfValidatedByLinkedTerminal)
        }
        if stringValues.contains("RestrictOverwriteIssuerExtraDara") {
            mask.update(with: SettingsMask.restrictOverwriteIssuerExtraData)
        }
        if stringValues.contains("RequireTermTxSignature") {
            mask.update(with: SettingsMask.requireTermTxSignature)
        }
        if stringValues.contains("RequireTermCertSignature") {
            mask.update(with: SettingsMask.requireTermCertSignature)
        }
        if stringValues.contains("CheckPIN3OnCard") {
            mask.update(with: SettingsMask.checkPIN3OnCard)
        }
        
        
        self = mask
    }
    
}



class SettingsMaskBuilder {
    private var settingsMaskValue = 0
    
    func add(_ settings: SettingsMask) {
        settingsMaskValue |= settings.rawValue
    }
    
    func build() -> SettingsMask {
        return SettingsMask(rawValue: settingsMaskValue)
    }
}

/// Detailed information about card contents.
public struct CardData: ResponseCodable {
    /// Tangem internal manufacturing batch ID.
    public let batchId: String?
    /// Timestamp of manufacturing.
    public let manufactureDateTime: Date?
    /// Name of the issuer.
    public let issuerName: String?
    /// Name of the blockchain.
    public let blockchainName: String?
    /// Signature of CardId with manufacturer’s private key.
    public let manufacturerSignature: Data?
    /// Mask of products enabled on card.
    public let productMask: ProductMask?
    /// Name of the token.
    public let tokenSymbol: String?
    /// Smart contract address.
    public let tokenContractAddress: String?
    /// Number of decimals in token value.
    public let tokenDecimal: Int?
}

extension CardData {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        batchId = try? values.decode(String.self, forKey: .batchId)
        manufactureDateTime = try? values.decode(Date.self, forKey: .manufactureDateTime)
        issuerName = try? values.decode(String.self, forKey: .issuerName)
        blockchainName = try? values.decode(String.self, forKey: .blockchainName)
        manufacturerSignature = try? values.decode(Data.self, forKey: .manufacturerSignature)
        if let productMaskDictionary = try? values.decode([String:UInt8].self, forKey: .productMask),
            let rawValue = productMaskDictionary["rawValue"]  {
            productMask = ProductMask(rawValue: rawValue)
        } else {
            productMask = try values.decode(ProductMask.self, forKey: .productMask)
        }
        tokenSymbol = try? values.decode(String.self, forKey: .tokenSymbol)
        tokenContractAddress = try? values.decode(String.self, forKey: .tokenContractAddress)
        tokenDecimal = try? values.decode(Int.self, forKey: .tokenDecimal)
    }
}

///Response for `ReadCommand`. Contains detailed card information.
public struct Card: ResponseCodable {
    /// Unique Tangem card ID number.
    public let cardId: String?
    /// Name of Tangem card manufacturer.
    public let manufacturerName: String?
    /// Current status of the card.
    public let status: CardStatus?
    /// Version of Tangem COS.
    public let firmwareVersion: String?
    /// Public key that is used to authenticate the card against manufacturer’s database.
    /// It is generated one time during card manufacturing.
    public let cardPublicKey: Data?
    /// Card settings defined by personalization (bit mask: 0 – Enabled, 1 – Disabled).
    public let settingsMask: SettingsMask?
    /// Public key that is used by the card issuer to sign IssuerData field.
    public let issuerPublicKey: Data?
    /// Explicit text name of the elliptic curve used for all wallet key operations.
    /// Supported curves: ‘secp256k1’ and ‘ed25519’.
    public let curve: EllipticCurve?
    /// Total number of signatures allowed for the wallet when the card was personalized.
    public let maxSignatures: Int?
    /// Defines what data should be submitted to SIGN command.
    public let signingMethods: SigningMethod?
    /// Delay in centiseconds before COS executes commands protected by PIN2. This is a security delay value
    public let pauseBeforePin2: Int?
    /// Public key of the blockchain wallet.
    public let walletPublicKey: Data?
    /// Remaining number of `SignCommand` operations before the wallet will stop signing transactions.
    public let walletRemainingSignatures: Int?
    /// Total number of signed single hashes returned by the card in
    /// `SignCommand` responses since card personalization.
    /// Sums up array elements within all `SignCommand`.
    public let walletSignedHashes: Int?
    /// Any non-zero value indicates that the card experiences some hardware problems.
    /// User should withdraw the value to other blockchain wallet as soon as possible.
    /// Non-zero Health tag will also appear in responses of all other commands.
    public let health: Int?
    /// Whether the card requires issuer’s confirmation of activation
    public let isActivated: Bool
    /// A random challenge generated by personalisation that should be signed and returned
    /// to COS by the issuer to confirm the card has been activated.
    /// This field will not be returned if the card is activated
    public let activationSeed: Data?
    /// Returned only if `SigningMethod.SignPos` enabling POS transactions is supported by card
    public let paymentFlowVersion: Data?
    /// This value can be initialized by terminal and will be increased by COS on execution of every `SignCommand`.
    /// For example, this field can store blockchain “nonce” for quick one-touch transaction on POS terminals.
    /// Returned only if `SigningMethod.SignPos`  enabling POS transactions is supported by card.
    public let userCounter: Int?
    /// When this value is true, it means that the application is linked to the card,
    /// and COS will not enforce security delay if `SignCommand` will be called
    /// with `TlvTag.TerminalTransactionSignature` parameter containing a correct signature of raw data
    /// to be signed made with `TlvTag.TerminalPublicKey`.
    public let terminalIsLinked: Bool
    /// Detailed information about card contents. Format is defined by the card issuer.
    /// Cards complaint with Tangem Wallet application should have TLV format.
    public let cardData: CardData?
    
    //MARK: Dynamic NDEF
    /// Remaining number of allowed transaction signatures
    @available(*, deprecated, message: "Use walletRemainingSignatures instead")
    public let remainingSignatures: Int?
    /// Number of hashes signed after personalization (there can be
    /// severeal hases in one transaction)
    @available(*, deprecated, message: "Use walletSignedHashes instead")
    public var signedHashes: Int?
    /// First part of a message signed by card
    @available(*, deprecated, message: "Will be removed in future version")
    public let challenge: Data?
    /// Second part of a message signed by card
    @available(*, deprecated, message: "Will be removed in future version")
    public let salt: Data?
    /// [Challenge, Salt] SHA256 signature signed with Wallet_PrivateKey
    @available(*, deprecated, message: "Will be removed in future version")
    public let walletSignature: Data?
    
    public init(cardId: String?, manufacturerName: String?, status: CardStatus?, firmwareVersion: String?, cardPublicKey: Data?, settingsMask: SettingsMask?, issuerPublicKey: Data?, curve: EllipticCurve?, maxSignatures: Int?, signingMethods: SigningMethod?, pauseBeforePin2: Int?, walletPublicKey: Data?, walletRemainingSignatures: Int?, walletSignedHashes: Int?, health: Int?, isActivated: Bool, activationSeed: Data?, paymentFlowVersion: Data?, userCounter: Int?, terminalIsLinked: Bool, cardData: CardData?, remainingSignatures: Int? = nil, signedHashes: Int? = nil, challenge: Data? = nil, salt: Data? = nil, walletSignature: Data? = nil) {
        self.cardId = cardId
        self.manufacturerName = manufacturerName
        self.status = status
        self.firmwareVersion = firmwareVersion
        self.cardPublicKey = cardPublicKey
        self.settingsMask = settingsMask
        self.issuerPublicKey = issuerPublicKey
        self.curve = curve
        self.maxSignatures = maxSignatures
        self.signingMethods = signingMethods
        self.pauseBeforePin2 = pauseBeforePin2
        self.walletPublicKey = walletPublicKey
        self.walletRemainingSignatures = walletRemainingSignatures
        self.walletSignedHashes = walletSignedHashes
        self.health = health
        self.isActivated = isActivated
        self.activationSeed = activationSeed
        self.paymentFlowVersion = paymentFlowVersion
        self.userCounter = userCounter
        self.terminalIsLinked = terminalIsLinked
        self.cardData = cardData
        self.remainingSignatures = remainingSignatures
        self.signedHashes = signedHashes
        self.challenge = challenge
        self.salt = salt
        self.walletSignature = walletSignature
    }
}

public enum CardType {
    case sdk
    case release
    case unknown
}

public extension Card {
    private static let firmwareSdkLiteral = "d SDK"
    private static let firmwareReleaseLiteral = "r"
    
    var firmwareVersionValue: Double? {
        if let firmwareVersion = firmwareVersion?.remove(Card.firmwareSdkLiteral).remove(Card.firmwareReleaseLiteral).remove("\0") {
            return Double(firmwareVersion)
        }
        return nil
    }
    
    var isLinkedTerminalSupported: Bool {
        return settingsMask?.contains(SettingsMask.skipSecurityDelayIfValidatedByLinkedTerminal) ?? false
    }
    
    var cardType: CardType {
        guard let firmwareVersion = firmwareVersion else  {
            return .unknown
        }
        
        if firmwareVersion.hasSuffix(Card.firmwareSdkLiteral) {
            return .sdk
        }
        
        if firmwareVersion.hasSuffix(Card.firmwareReleaseLiteral) {
            return .release
        }
        
        return .unknown
    }
}

/// This command receives from the Tangem Card all the data about the card and the wallet,
///  including unique card number (CID or cardId) that has to be submitted while calling all other commands.
@available(iOS 13.0, *)
public final class ReadCommand: Command {
    public typealias CommandResponse = ReadResponse
    
    public var needPreflightRead: Bool {
        return false
    }
    
    public init() {}
    deinit {
        print("ReadCommand deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<ReadResponse>) {
        transieve(in: session) { result in
            switch result {
            case .success(let readResponse):
                session.environment.card = readResponse
                completion(.success(readResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
        if case .invalidParams = error {
            return .pin1Required
        }
        
        return error
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        /// `SessionEnvironment` stores the pin1 value. If no pin1 value was set, it will contain
        /// default value of ‘000000’.
        /// In order to obtain card’s data, [ReadCommand] should use the correct pin 1 value.
        /// The card will not respond if wrong pin 1 has been submitted.
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1.value)
        if let keys = environment.terminalKeys {
            try tlvBuilder.append(.terminalPublicKey, value: keys.publicKey)
        }
        
        return CommandApdu(.read, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadResponse {
        return try CardDeserializer.deserialize(with: environment, from: apdu)
    }
}

struct CardDeserializer {
    static func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        let card = ReadResponse(
            cardId: try decoder.decodeOptional(.cardId),
            manufacturerName: try decoder.decodeOptional(.manufacturerName),
            status: try decoder.decodeOptional(.status),
            firmwareVersion: try decoder.decodeOptional(.firmwareVersion),
            cardPublicKey: try decoder.decodeOptional(.cardPublicKey),
            settingsMask: try decoder.decodeOptional(.settingsMask),
            issuerPublicKey: try decoder.decodeOptional(.issuerPublicKey),
            curve: try decoder.decodeOptional(.curveId),
            maxSignatures: try decoder.decodeOptional(.maxSignatures),
            signingMethods: try decoder.decodeOptional(.signingMethod),
            pauseBeforePin2: try decoder.decodeOptional(.pauseBeforePin2),
            walletPublicKey: try decoder.decodeOptional(.walletPublicKey),
            walletRemainingSignatures: try decoder.decodeOptional(.walletRemainingSignatures),
            walletSignedHashes: try decoder.decodeOptional(.walletSignedHashes),
            health: try decoder.decodeOptional(.health),
            isActivated: try decoder.decode(.isActivated),
            activationSeed: try decoder.decodeOptional(.activationSeed),
            paymentFlowVersion: try decoder.decodeOptional(.paymentFlowVersion),
            userCounter: try decoder.decodeOptional(.userCounter),
            terminalIsLinked: try decoder.decode(.isLinked),
            cardData: try deserializeCardData(tlv: tlv),
            remainingSignatures: try decoder.decodeOptional(.walletRemainingSignatures),
            signedHashes: try decoder.decodeOptional(.walletSignedHashes),
            challenge: try decoder.decodeOptional(.challenge),
            salt: try decoder.decodeOptional(.salt),
            walletSignature: try decoder.decodeOptional(.walletSignature))
        
        return card
    }
    
    static private func deserializeCardData(tlv: [Tlv]) throws -> CardData? {
        guard let cardDataValue = tlv.value(for: .cardData),
            let cardDataTlv = Tlv.deserialize(cardDataValue) else {
                return nil
        }
        
        let decoder = TlvDecoder(tlv: cardDataTlv)
        let cardData = CardData(
            batchId: try decoder.decodeOptional(.batchId),
            manufactureDateTime: try decoder.decodeOptional(.manufactureDateTime),
            issuerName: try decoder.decodeOptional(.issuerName),
            blockchainName: try decoder.decodeOptional(.blockchainName),
            manufacturerSignature: try decoder.decodeOptional(.cardIDManufacturerSignature),
            productMask: try decoder.decodeOptional(.productMask),
            tokenSymbol: try decoder.decodeOptional(.tokenSymbol),
            tokenContractAddress: try decoder.decodeOptional(.tokenContractAddress),
            tokenDecimal: try decoder.decodeOptional(.tokenDecimal))
        
        return cardData
    }
}
