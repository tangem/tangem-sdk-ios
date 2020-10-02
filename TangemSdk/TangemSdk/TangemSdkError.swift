//
//  TangemSdkError.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 18.03.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

/**
 * An error class that represent typical errors that may occur when performing Tangem SDK tasks.
 * Errors are propagated back to the caller in callbacks.
 */
public enum TangemSdkError: Error, LocalizedError, Encodable {
    //MARK: NFC processing errors
    
    /// This error is returned when  NFC reader loses a tag
    /// (e.g. a user detaches card from the phone's NFC module) while the NFC session is in progress.
    case tagLost
    
    /// Command was sent to wrong tag type
    case unsupportedCommand
    
    /// This error is returned when the current device doesn't support the desired NFC operations
    case unsupportedDevice
    
    /// Start session before
    case sessionInactive
    
    /// It seems that NFC does not work properly on your iPhone. Try to reboot your iPhone
    case nfcStuck
    
    case nfcTimeout
    
    case nfcReaderError

    
    //MARK: Apdu processing errrors
    
    case serializeCommandError
    
    /// This error is returned when the `ResponseApdu` cannot deserialize bytes to `[Tlv]`
    case deserializeApduFailed
    
    /// This error is returned when the `TlvEncoder` failed to encode value not matching `TlvTag` value type
    case encodingFailedTypeMismatch
    
    /// This error is returned when the `TlvEncoder` failed to encode nil value or failed to encode stiring with utf8 encoding
    case encodingFailed
    
    /// This error is returned when the `TlvDecoder` cannot find desired tag. You can use `decodeOptional` to handle this error automatically
    case decodingFailedMissingTag
    
    /// This error is returned when the `TlvDecoder` failed to decode value not matching `TlvTag` value type
    case decodingFailedTypeMismatch
    
    /// This error is returned when the `TlvDecoder` failed to decode value. Please let us know
    case decodingFailed
    
    case failedToEncryptApdu
    
    case failedToDecryptApdu
    
    case failedToEstablishEncryption
    
    case invalidResponseApdu
    
    //MARK: Card errrors
    
    /// This error is returned when unknown `StatusWord` is received from a card.
    case unknownStatus
    
    /// This error is returned when a card's reply is `StatusWord.ErrorProcessingCommand`.
    /// The card sends this status in case of internal card error
    case errorProcessingCommand
    
    /// This error is returned when a card's reply is `StatusWord.InvalidState`.
    /// The card sends this status when command can not be executed in the current state of a card.
    case invalidState
    
    /// This error is returned when a card's reply is `StatusWord.InsNotSupported`.
    /// The card sends this status when the card cannot process the `Instruction`.
    case insNotSupported
    
    /// This error is returned when a card's reply is `StatusWord.InvalidParams`.
    /// The card sends this status when there are wrong or not sufficient parameters in `TLV` request, or wrong `PIN1/PIN2`.
    /// The error may be caused, for example, by wrong parameters of the `ApduSerializable`, encode/decode  errors.
    case invalidParams
    
    /// This error is returned when a card's reply is `StatusWord.NeedEncryption` and the encryption was not established by TangemSdk.
    case needEncryption
    
    
    //MARK: Business logic errors
    
    // Personalization Errors
    case alreadyPersonalized
    
    // Depersonalization Errors
    case cannotBeDepersonalized
    
    // Read Errors
    case pin1Required
    
    // CreateWallet Errors
    case alreadyCreated
    
    // PurgeWallet Errors
    case purgeWalletProhibited
    
    // SetPin Errors
    case pin1CannotBeChanged
    case pin2CannotBeChanged
    case pin1CannotBeDefault
    
    //Sign Errors
    case noRemainingSignatures
    
    /// This error is returned when a `SignCommand` receives only empty hashes for signature.
    case emptyHashes
    
    /// This error is returned when a `SignCommand` receives hashes of different lengths for signature.
    case hashSizeMustBeEqual
    
    case cardIsEmpty
    
    case signHashesNotAvailable
    
    /// Tangem cards can sign currently up to 10 hashes during one `SignCommand`.
    /// This error is returned when a `SignCommand` receives more than 10 hashes to sign.
    case tooManyHashesInOneTransaction
    
    // Write Extra Issuer Data Errors
    case extendedDataSizeTooLarge
    
    // General Errors
    
    case notPersonalized
    
    case notActivated
    
    case cardIsPurged
    
    case pin2OrCvcRequired
    
    /// This error is returned when SDK checks unsuccessfully either
    /// a card's ability to sign with its private key, or the validity of issuer data.
    case verificationFailed
    
    case cardVerificationFailed
    
    /// This error is returned when a [Task] checks unsuccessfully either
    /// a card's ability to sign with its private key, or the validity of issuer data.
    case dataSizeTooLarge
    
    /// This error is returned when `ReadIssuerData` or `ReadIssuerExtraData` expects a counter
    /// (when the card's requires it), but the counter is missing.
    case missingCounter
    
    case overwritingDataIsProhibited
    
    case dataCannotBeWritten
    
    /// This error is returned when `issuerPublicKey` requires to perform operation
    case missingIssuerPublicKey
    
    
    //MARK: SDK errors
    
    case unknownError
    
    case underlying(error: Error)
    
    /// This error is returned when a user manually closes the NFC  Dialog.
    case userCancelled
    
    /// This error is returned when `CardSession`  was called with a new operation,  while a previous operation is still in progress.
    case busy
    
    /// This error is returned when a `CardSessionRunnable` requires that `ReadCommand`
    /// is executed before performing other commands.
    case missingPreflightRead
    
    /// This error is returned when a [Task] expects a user to use a particular card,
    /// but the user tries to use a different card.
    case wrongCardNumber
    
    /// This error is returned when a user scans a card of a [com.tangem.common.extensions.CardType]
    /// that is not specified in [Config.cardFilter].
    case wrongCardType
    
    /// This error is returned when the scanned card doesn't have some essential fields.
    case cardError
    
    /// This error is returned when SDK fails to perform some low-level crypto algorithm
    case cryptoUtilsError
    
    /// This error is returned when the error occurs inside third-party crypto libraries code
    case failedToGenerateRandomSequence
    
    //MARK: Underlying NFC reader errors
    case readerErrorUnsupportedFeature
    case readerErrorSecurityViolation
    case readerErrorInvalidParameter
    case readerErrorInvalidParameterLength
    case readerErrorParameterOutOfBound
    case readerTransceiveErrorTagConnectionLost
    case readerTransceiveErrorRetryExceeded
    case readerTransceiveErrorTagResponseError
    case readerTransceiveErrorSessionInvalidated
    case readerTransceiveErrorTagNotConnected
    case readerSessionInvalidationErrorSessionTimeout
    case readerSessionInvalidationErrorSessionTerminatedUnexpectedly
    case readerSessionInvalidationErrorFirstNDEFTagRead
    case tagCommandConfigurationErrorInvalidParameters
    case ndefReaderSessionErrorTagNotWritable
    case ndefReaderSessionErrorTagUpdateFailure
    case ndefReaderSessionErrorTagSizeTooSmall
    case ndefReaderSessionErrorZeroLengthMessage
    
    public var code: Int {
        switch self {
        case .alreadyCreated: return 40501
        case .alreadyPersonalized: return 40101
        case .busy: return 50003
        case .cannotBeDepersonalized: return 40201
        case .cardError: return 50007
        case .cardIsEmpty: return 40904
        case .cardIsPurged: return 40003
        case .cryptoUtilsError: return 50008
        case .dataCannotBeWritten: return 40009
        case .dataSizeTooLarge: return 40006
        case .decodingFailed: return 20007
        case .decodingFailedMissingTag: return 20005
        case .decodingFailedTypeMismatch: return 20006
        case .deserializeApduFailed: return 20002
        case .emptyHashes: return 40902
        case .encodingFailed: return 20004
        case .encodingFailedTypeMismatch: return 20003
        case .errorProcessingCommand: return 30002
        case .extendedDataSizeTooLarge: return 41101
        case .failedToDecryptApdu: return 20009
        case .failedToEncryptApdu: return 20008
        case .failedToEstablishEncryption: return 20010
        case .failedToGenerateRandomSequence: return 50009
        case .hashSizeMustBeEqual: return 40903
        case .insNotSupported: return 30004
        case .invalidParams: return 30005
        case .invalidResponseApdu: return 20011
        case .invalidState: return 30003
        case .missingCounter: return 40007
        case .missingIssuerPublicKey: return 40010
        case .missingPreflightRead: return 50004
        case .ndefReaderSessionErrorTagNotWritable: return 90017
        case .ndefReaderSessionErrorTagSizeTooSmall: return 90019
        case .ndefReaderSessionErrorTagUpdateFailure: return 90018
        case .ndefReaderSessionErrorZeroLengthMessage: return 90020
        case .needEncryption: return 30006
        case .nfcReaderError: return 10008
        case .nfcStuck: return 10006
        case .nfcTimeout: return 10007
        case .noRemainingSignatures: return 40901
        case .notActivated: return 40002
        case .notPersonalized: return 40001
        case .overwritingDataIsProhibited: return 40008
        case .pin1CannotBeChanged: return 40801
        case .pin1CannotBeDefault: return 40803
        case .pin1Required: return 40401
        case .pin2CannotBeChanged: return 40802
        case .pin2OrCvcRequired: return 40004
        case .purgeWalletProhibited: return 40601
        case .readerErrorInvalidParameter: return 90005
        case .readerErrorInvalidParameterLength: return 90006
        case .readerErrorParameterOutOfBound: return 90007
        case .readerErrorSecurityViolation: return 90004
        case .readerErrorUnsupportedFeature: return 90003
        case .readerSessionInvalidationErrorFirstNDEFTagRead: return 90015
        case .readerSessionInvalidationErrorSessionTerminatedUnexpectedly: return 90014
        case .readerSessionInvalidationErrorSessionTimeout: return 90013
        case .readerTransceiveErrorRetryExceeded: return 90009
        case .readerTransceiveErrorSessionInvalidated: return 90011
        case .readerTransceiveErrorTagConnectionLost: return 90008
        case .readerTransceiveErrorTagNotConnected: return 90012
        case .readerTransceiveErrorTagResponseError: return 90010
        case .serializeCommandError: return 20001
        case .sessionInactive: return 10005
        case .signHashesNotAvailable: return 40905
        case .tagCommandConfigurationErrorInvalidParameters: return 90016
        case .tagLost: return 10001
        case .tooManyHashesInOneTransaction: return 40906
        case .unknownError: return 50001
        case .unknownStatus: return 30001
        case .unsupportedCommand: return 10003
        case .unsupportedDevice: return 10004
        case .userCancelled: return 50002
        case .verificationFailed: return 40005
        case .cardVerificationFailed: return 40011
        case .wrongCardNumber: return 50005
        case .wrongCardType: return 50006
        case .underlying: return 50010
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .nfcTimeout: return Localization.nfcSessionTimeout
        case .nfcStuck: return Localization.nfcStuckError
        case .alreadyCreated: return Localization.string("error_already_created")
        case .alreadyPersonalized: return Localization.string("error_already_personalized")
        case .busy: return Localization.string("error_busy")
        case .cannotBeDepersonalized: return Localization.string("error_cannot_be_depersonalized")
        case .cardError: return Localization.string("error_card_error")
        case .cardIsEmpty: return Localization.string("error_card_is_empty")
        case .cardIsPurged: return Localization.string("error_purged")
        case .dataCannotBeWritten: return Localization.string("error_data_cannot_be_written")
        case .dataSizeTooLarge: return Localization.string("error_data_size_too_large")
        case .emptyHashes: return Localization.string("error_empty_hashes")
        case .extendedDataSizeTooLarge: return Localization.string("error_data_size_too_large_extended")
        case .hashSizeMustBeEqual: return Localization.string("error_cannot_be_signed")
        case .missingCounter: return Localization.string("error_missing_counter")
        case .missingIssuerPublicKey: return Localization.string("error_missing_issuer_public_key")
        case .noRemainingSignatures: return Localization.string("error_no_remaining_signatures")
        case .notActivated: return Localization.string("error_not_activated")
        case .notPersonalized: return Localization.string("error_not_personalized")
        case .overwritingDataIsProhibited: return Localization.string("error_data_cannot_be_written")
        case .pin1CannotBeChanged: return Localization.string("error_pin1_cannot_be_changed")
        case .pin1CannotBeDefault: return Localization.string("error_pin1_cannot_be_default")
        case .pin2CannotBeChanged: return Localization.string("error_pin2_cannot_be_changed")
        case .purgeWalletProhibited: return Localization.string("error_purge_prohibited")
        case .signHashesNotAvailable: return Localization.string("error_cannot_be_signed")
        case .tagLost: return Localization.string("error_tag_lost")
        case .tooManyHashesInOneTransaction: return Localization.string("error_cannot_be_signed")
        case .userCancelled: return Localization.string("error_user_cancelled")
        case .verificationFailed: return Localization.string("error_verification_failed")
        case .cardVerificationFailed: return Localization.string("error_card_verification_failed")
        case .wrongCardNumber: return Localization.string("error_wrong_card_number")
        case .wrongCardType: return Localization.string("error_wrong_card_type")
        case .pin1Required: return Localization.string("error_pin1_required")
        case .pin2OrCvcRequired: return Localization.string("error_pin2_required")
        case .underlying(let error): return error.localizedDescription
        default:
            let description = "\(self)".capitalizingFirst()
            return Localization.genericErrorCode("\(self.code). \(description)")
        }
    }
    
    public var jsonDescription: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let data = (try? encoder.encode(self)) ?? Data()
        return String(data: data, encoding: .utf8)!
    }
    
    public var isUserCancelled: Bool {
        if case .userCancelled = self {
            return true
        } else {
            return false
        }
    }
    
    public static func parse(_ error: Error) -> TangemSdkError {
        if let readerError = error as? NFCReaderError {
            switch readerError.code {
            case .readerSessionInvalidationErrorUserCanceled:
                return .userCancelled
            case .readerSessionInvalidationErrorSystemIsBusy:
                return .nfcStuck
            case .readerErrorUnsupportedFeature:
                return .readerErrorUnsupportedFeature
            case .readerErrorSecurityViolation:
                return .readerErrorSecurityViolation
            case .readerErrorInvalidParameter:
                return .readerErrorInvalidParameter
            case .readerErrorInvalidParameterLength:
                return .readerErrorInvalidParameterLength
            case .readerErrorParameterOutOfBound:
                return readerErrorParameterOutOfBound
            case .readerTransceiveErrorTagConnectionLost:
                return .readerTransceiveErrorTagConnectionLost
            case .readerTransceiveErrorRetryExceeded:
                return .readerTransceiveErrorRetryExceeded
            case .readerTransceiveErrorTagResponseError:
                return .readerTransceiveErrorTagResponseError
            case .readerTransceiveErrorSessionInvalidated:
                return .readerTransceiveErrorSessionInvalidated
            case .readerTransceiveErrorTagNotConnected:
                return .readerTransceiveErrorTagNotConnected
            case .readerSessionInvalidationErrorSessionTimeout:
                return readerSessionInvalidationErrorSessionTimeout
            case .readerSessionInvalidationErrorSessionTerminatedUnexpectedly:
                return .readerSessionInvalidationErrorSessionTerminatedUnexpectedly
            case .readerSessionInvalidationErrorFirstNDEFTagRead:
                return .readerSessionInvalidationErrorFirstNDEFTagRead
            case .tagCommandConfigurationErrorInvalidParameters:
                return .tagCommandConfigurationErrorInvalidParameters
            case .ndefReaderSessionErrorTagNotWritable:
                return .ndefReaderSessionErrorTagNotWritable
            case .ndefReaderSessionErrorTagUpdateFailure:
                return .ndefReaderSessionErrorTagUpdateFailure
            case .ndefReaderSessionErrorTagSizeTooSmall:
                return .ndefReaderSessionErrorTagSizeTooSmall
            case .ndefReaderSessionErrorZeroLengthMessage:
                return .ndefReaderSessionErrorZeroLengthMessage
            @unknown default:
                return .nfcReaderError
            }
        } else {
            return (error as? TangemSdkError) ?? TangemSdkError.underlying(error: error)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var error = [String:String]()
        error["code"] = String(describing: code)
        error["localizedDescription"] = localizedDescription
        var container = encoder.singleValueContainer()
        try container.encode(error)
    }
    
    static func from(pinType: PinCode.PinType) -> TangemSdkError {
        switch pinType {
        case .pin1:
            return .pin1Required
        case .pin2:
            return .pin2OrCvcRequired
        case .pin3:
            return .unknownError
        }
    }
}
