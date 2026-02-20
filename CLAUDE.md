# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Tangem SDK for iOS — an NFC-based hardware wallet SDK for Tangem cards. Facilitates secure key creation/storage and data signing via NFC. Distributed via Swift Package Manager and CocoaPods.

- **iOS minimum**: 16.4
- **Swift tools version**: 5.3
- **External dependency**: CryptoSwift 1.9.0

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

Tests run on simulator (iPhone 17 Pro Max, Xcode 26.2). Test output goes to `./test_output` in JUnit format via xcbeautify.

## Project Structure

```
TangemSdk/TangemSdk/          # SDK source (main target)
├── TangemSdk.swift            # Main public API class (entry point)
├── Common/
│   ├── APDU/                  # ISO7816 APDU command/response types
│   ├── Card/                  # Card data model structs
│   ├── Core/                  # CardSession, SessionEnvironment, errors
│   ├── Deserialization/       # TLV → Card/Wallet deserializers
│   ├── Encryption/            # AES encryption for secure channel
│   ├── Localization/          # 9 languages, managed via Lokalise
│   ├── NFC/                   # NFCReader (CoreNFC wrapper)
│   ├── Secure/                # SecureEnclaveService, AccessCodeRepository
│   ├── TLV/                   # Tag-Length-Value encoding/decoding
│   └── V8/                    # V8 firmware-specific support
├── Crypto/                    # secp256k1, EdDSA, BLS, BIP32/BIP39, HD wallets
├── Operations/                # All card commands and tasks
│   ├── Read/                  # ReadCommand, ScanTask
│   ├── Sign/                  # SignCommand
│   ├── Attestation/           # Card authenticity verification
│   ├── Backup/                # Wallet backup/restore
│   ├── Personalization/       # Card initialization
│   ├── Wallet/                # Create/purge wallets
│   ├── Pins/                  # Access code & passcode management
│   └── ...                    # Derivation, Files, ResetCode, UserSettings
├── UI/                        # SwiftUI views and SessionViewDelegate
└── Frameworks/                # Bls_Signature.xcframework (binary)

TangemSdk/TangemSdkTests/     # Unit tests with JSON fixtures in Jsons/
Example/                       # Example app (TangemSdkExample.xcodeproj)
```

### SPM Targets

- `TangemSdk` — main library
- `TangemSdk_secp256k1` — C library for secp256k1 (path: `TangemSdk/TangemSdk/Crypto/secp256k1`)
- `Bls_Signature` — binary xcframework for BLS signatures
- `TangemSdkTests` — test target

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

- **`CardSessionRunnable`** — interface for anything executable in a card session. Defines `run(in:completion:)`, preflight read mode, and encryption mode.
- **`Command`** — extends `CardSessionRunnable` with APDU serialization/deserialization (`serialize`/`deserialize`), pre-checks, and error mapping.
- **`CardReader`** — NFC transport abstraction. Default: `NFCReader` (CoreNFC).
- **`SessionViewDelegate`** — UI callback protocol for scan states, security delays, code requests.

### Core Types

- **`TangemSdk`** — public facade. All SDK operations start here (scanCard, sign, createWallet, etc.).
- **`CardSession`** — manages a single NFC session. Holds `SessionEnvironment` with card state, encryption, and user codes.
- **`Card`** — complete card state snapshot (cardId, firmware, wallets, settings, attestation, backup status).
- **`SessionEnvironment`** — mutable execution context (card data, encryption key/mode, user codes, terminal keys).

### Layers

1. **API** — `TangemSdk` public methods
2. **Session** — `CardSession` lifecycle, preflight reads, view delegation
3. **Operations** — Commands (ReadCommand, SignCommand, etc.) and Tasks (ScanTask, AttestationTask)
4. **TLV/APDU** — data encoding with `TlvBuilder`/`TlvEncoder`/`TlvDecoder`, `CommandApdu`/`ResponseApdu`
5. **Transport** — `CardReader`/`NFCReader` (CoreNFC), session management, retry logic
6. **Security** — encryption negotiation (none/fast/strong/CCM), security delay handling, access code caching with biometrics
7. **Crypto** — secp256k1, EdDSA, BLS, BIP32/BIP44 HD wallet derivation

### Error Handling

`TangemSdkError` defines 50+ specific error cases. Commands can override `performPreCheck()` for validation and `mapError()` for error translation. Security delays and encryption upgrades are handled automatically with retry.

### Firmware Versioning

Feature availability is gated by `FirmwareVersion` (v1.16+, v2.28+, v4+, v8+). Commands check firmware before execution.

## Git & CI

- **Main branch**: `develop`
- **Release branches**: `release/X.Y.Z` → merged to `master` → published to CocoaPods
- **Commit message style**: `IOS-XXXXX Description (#PR)` (Jira ticket prefix)
- **CI**: GitHub Actions runs `bundle exec fastlane test` on PRs to `develop` and `release/**`
- **Version**: stored in `VERSION` file (currently 4.1.0), also in `TangemSdk.podspec`
