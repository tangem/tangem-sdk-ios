# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Tangem SDK for iOS — an NFC-based hardware wallet SDK for Tangem cards. Facilitates secure key creation/storage and data signing via NFC. Distributed via Swift Package Manager and CocoaPods.

- **iOS minimum**: 16.4
- **Swift tools version**: 5.3
- **External dependency**: CryptoSwift 1.9.0 (pinned exact)

## Build & Test Commands

```bash
# Run tests via Fastlane (primary method, used by CI)
bundle install
bundle exec fastlane test

# Run tests via SPM directly
swift test

# Build via SPM
swift build
```

Tests run on simulator (iPhone 17 Pro Max, Xcode 26.2). Test output goes to `./test_output` in JUnit format via xcbeautify. Fastlane has a 120s xcodebuild settings timeout with 4 retries.

## Project Structure

```
TangemSdk/TangemSdk/              # SDK source (main target)
├── TangemSdk.swift                # Main public API class (entry point)
├── APDU/                          # ISO7816 APDU command/response types
├── Card/                          # Card data model structs
├── CardArtworks/                  # Card artwork providers and verification
├── Common/                        # Shared utilities (CardFilter, KeyPair, SignData, etc.)
├── Core/                          # CardSession, SessionEnvironment, TangemSdkError
├── Crypto/                        # secp256k1, EdDSA, BLS, BIP32/BIP39, HD wallets
│   └── secp256k1/                 # C library (separate SPM target)
├── Deserialization/               # TLV → Card/Wallet/MasterSecret deserializers
├── Encryption/                    # AES encryption (CBC + CCM modes for secure channel)
├── Extensions/                    # Swift type extensions (~29 files)
├── JSON/                          # JSON conversion and JSONRPC support
├── Localization/                  # 9 languages (en, fr, de, ja, ru, es, it, uk-UA, zh-Hant)
├── Log/                           # Logging infrastructure
├── NFC/                           # CardReader protocol, NFCReader (CoreNFC wrapper)
├── Network/                       # Network abstraction layer
├── OptionSet/                     # OptionSet utilities
├── Operations/                    # All card commands and tasks
│   ├── Command.swift              # Base Command protocol implementation
│   ├── PreflightReadTask.swift    # Auto-reads card before commands
│   ├── ScanTask.swift             # Full card scan task
│   ├── Read/                      # ReadCommand, ReadWalletCommand, ReadMasterSecretCommand
│   ├── Sign/                      # SignCommand
│   ├── Attestation/               # Card authenticity verification
│   ├── Backup/                    # Wallet backup/restore
│   ├── Derivation/                # BIP32 derivation tasks
│   ├── Files/                     # Read/Write/Delete file operations
│   ├── MasterSecret/              # CreateMasterSecret, PurgeMasterSecret (V8+)
│   ├── Personalization/           # Card initialization
│   ├── Pins/                      # Access code & passcode management
│   ├── SecureChannel/             # V8+ auth: AccessTokens, PIN, SecurityDelay
│   ├── Wallet/                    # Create/purge wallets
│   ├── IssuerAndUserData/         # Issuer data ops (deprecated, use Files)
│   ├── PreflightReadFilter/       # Preflight read filtering logic
│   ├── ResetCode/                 # Reset code operations
│   └── UserSettings/              # SetUserSettingsCommand
├── Secure/                        # SecureEnclaveService, AccessCodeRepository
├── TLV/                           # Tag-Length-Value encoding/decoding
├── UI/                            # SwiftUI views, SessionViewDelegate, ResetUserCodes
├── V8/                            # V8 firmware support (CardAccessTokens, SecureChannelSession)
├── Assets/                        # xcassets (heading, ring_shape_scan)
├── Haptics/                       # AHAP feedback files (Success, Error)
└── Frameworks/                    # Bls_Signature.xcframework (binary)

TangemSdk/TangemSdkTests/         # Unit tests with JSON fixtures in Jsons/
Example/                           # Example app (TangemSdkExample.xcodeproj)
```

### SPM Targets

- `TangemSdk` — main library
- `TangemSdk_secp256k1` — C library for secp256k1 (path: `TangemSdk/TangemSdk/Crypto/secp256k1`)
- `Bls_Signature` — binary xcframework for BLS signatures
- `TangemSdkTests` — test target (depends on TangemSdk + CryptoSwift)

## Architecture

### Execution Flow

```
TangemSdk (public API)
  → CardSession (manages NFC lifecycle, holds SessionEnvironment)
    → PreflightReadTask (auto-reads card before commands)
      → Command.run(in: session)
        → serialize → CommandApdu (TLV-encoded)
          → CardReader.sendPublisher (NFC transceive)
            → ResponseApdu → deserialize → typed response
```

### Key Protocols

- **`CardSessionRunnable`** — interface for anything executable in a card session. Defines `run(in:completion:)`, `preflightReadMode`, `shouldAskForAccessCode`, and `encryptionMode`.
- **`Command`** — extends `CardSessionRunnable` with APDU serialization/deserialization (`serialize`/`deserialize`), pre-checks (`performPreCheck`), error mapping (`mapError`), and `transceive`.
- **`ApduSerializable`** — APDU serialization interface with `serialize()`/`deserialize()` methods.
- **`CardReader`** — NFC transport abstraction. Default: `NFCReader` (CoreNFC). Methods: `sendPublisher`, `startSession`, `stopSession`, `pauseSession`.
- **`SessionViewDelegate`** — UI callback protocol for scan states, security delays, code requests.

### Core Types

- **`TangemSdk`** — public facade. All SDK operations start here (scanCard, sign, createWallet, importWallet, etc.).
- **`CardSession`** — manages a single NFC session. Holds `SessionEnvironment` with card state, encryption, and user codes.
- **`Card`** — complete card state snapshot (cardId, firmware, wallets, settings, attestation, backup status).
- **`SessionEnvironment`** — mutable execution context (card data, encryption key/mode, user codes, terminal keys, cardAccessTokens for V8).

### Layers

1. **API** — `TangemSdk` public methods
2. **Session** — `CardSession` lifecycle, preflight reads, view delegation
3. **Operations** — Commands (ReadCommand, SignCommand, etc.) and Tasks (ScanTask, AttestationTask)
4. **TLV/APDU** — data encoding with `TlvBuilder`/`TlvEncoder`/`TlvDecoder`, `CommandApdu`/`ResponseApdu`
5. **Transport** — `CardReader`/`NFCReader` (CoreNFC), session management, retry logic
6. **Security** — encryption negotiation, security delay handling, access code caching with biometrics
7. **Crypto** — secp256k1, EdDSA, BLS, BIP32/BIP44 HD wallet derivation

### Encryption Modes

```swift
enum EncryptionMode {
    case none
    case fast                      // CBC-Fast
    case strong                    // CBC-Strong
    case ccmWithSecurityDelay      // CCM, V8+ (COS v8)
    case ccmWithAccessToken        // CCM, V8+
    case ccmWithAsymmetricKeys     // CCM, V8+
}
```

CBC modes for pre-V8 firmware; CCM (Counter with CBC-MAC) modes for V8+ with three authorization variants.

### Error Handling

`TangemSdkError` defines 50+ specific error cases. Commands can override `performPreCheck()` for validation and `mapError()` for error translation. Security delays and encryption upgrades are handled automatically with retry.

### Firmware Versioning

Feature availability is gated by `FirmwareVersion`:
- **v4+**: Multi-wallet, backup, BLS
- **v6+**: Key imports, Ed25519 SLIP0010
- **v8** (v8.48+): Secure channel, CCM encryption, access tokens, master secret management

## Git & CI

- **Main branch**: `develop`
- **Feature branches**: e.g., `develop-fw8` (V8 firmware support)
- **Release branches**: `release/X.Y.Z` → merged to `master` → published to CocoaPods
- **Commit message style**: `IOS-XXXXX Description (#PR)` (Jira ticket prefix)
- **CI**: GitHub Actions on `macos-15`, runs `bundle exec fastlane test` on PRs to `develop` and `release/**`
- **Additional workflows**: publish-release, sync-to-public-repo, update-localizations (Lokalise), create-release-branch, check-tag, set-tag, generate-changelog
- **Version**: stored in `VERSION` file (currently 4.1.0), also in `TangemSdk.podspec`
