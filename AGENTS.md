# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code), Microsoft Copilot and other agents when working with code in this repository.

## Project Overview

Tangem iOS SDK — an NFC library for communicating with Tangem hardware wallet cards. Enables secure key generation, storage, and transaction signing via NFC. Distributed as both SPM package and CocoaPod.

- **SDK version**: stored in `VERSION` file (also in `TangemSdk.podspec`)
- **Xcode version**: stored in `.xcode-version` file
- **Swift tools version**: 5.3
- **iOS deployment target**: 16.4
- **External dependency**: CryptoSwift 1.9.0 (exact)

### Code Formatting
SwiftFormat runs automatically during bootstrap and is enforced by CI (Dangerfile). Manual run:
```bash
mint run swiftformat@0.55.5 . --config .swiftformat
```

### Code Generation
SwiftGen generates type-safe assets and localization:
```bash
mint run swiftgen@6.6.3 config run --config swiftgen.yml
```

## Build & Test Commands

```bash
# Run tests via Fastlane (CI-equivalent, uses xcbeautify formatter)
bundle exec fastlane test

# Run tests directly via xcodebuild (SPM-based)
# Device name and OS version are read from .ios-sim-runtime (line 1 = name, line 2 = OS)
xcodebuild test \
  -scheme TangemSdk \
  -destination "platform=iOS Simulator,name=$(sed -n '1p' .ios-sim-runtime),OS=$(sed -n '2p' .ios-sim-runtime)" \
  -skipPackagePluginValidation

# Run a single test
xcodebuild test \
  -scheme TangemSdk \
  -destination "platform=iOS Simulator,name=$(sed -n '1p' .ios-sim-runtime),OS=$(sed -n '2p' .ios-sim-runtime)" \
  -only-testing:TangemSdkTests/BIP32Tests/testName

# Build via SPM
swift build

# Run tests via SPM directly
swift test

# Install Ruby dependencies (needed for Fastlane)
bundle install
```

The project builds as an SPM package (no .xcodeproj scheme needed for the SDK itself). The `TangemSdk.xcworkspace` exists but the primary build path is SPM via `Package.swift`.

Test output goes to `./test_output` in JUnit format via xcbeautify. Fastlane has a 120s xcodebuild settings timeout with 4 retries.

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

## Architecture

### Core Abstractions

The SDK follows a **Command Pattern** built on three key protocols:

1. **`CardSessionRunnable`** (`Common/Core/CardSessionRunnable.swift`) — base protocol for anything that runs in an NFC session. Defines `run(in:completion:)`, preflight read mode, encryption mode, and access code policy.

2. **`Command`** (`Operations/Command.swift`) — extends `CardSessionRunnable` + `ApduSerializable`. Adds APDU serialize/deserialize, passcode requirements, pre-checks, and error mapping. All card operations implement this.

3. **`ApduSerializable`** — serialize to `CommandApdu`, deserialize from `ResponseApdu` using TLV encoding.

4. **`CardReader`** — NFC transport abstraction. Default: `NFCReader` (CoreNFC). Methods: `sendPublisher`, `startSession`, `stopSession`, `pauseSession`.

5. **`SessionViewDelegate`** — UI callback protocol for scan states, security delays, code requests.

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

### Core Types

- **`TangemSdk`** — public facade. All SDK operations start here (scanCard, sign, createWallet, importWallet, etc.).
- **`CardSession`** — manages a single NFC session. Holds `SessionEnvironment` with card state, encryption, and user codes.
- **`Card`** — complete card state snapshot (cardId, firmware, wallets, settings, attestation, backup status).
- **`SessionEnvironment`** — mutable execution context (card data, encryption key/mode, user codes, terminal keys, cardAccessTokens for V8).

### Session Lifecycle

`TangemSdk` (main entry point) → creates `CardSession` → manages `CardReader` (NFC) + `SessionViewDelegate` (UI) → runs `CardSessionRunnable` implementations.

- `CardSession` manages NFC connection state, encryption negotiation, security delay handling, and access code prompts
- `SessionEnvironment` carries per-session state (card data, encryption keys, passcodes, config)
- `SessionFilter` constrains which card can be used in a session

### Communication Protocol

Card ↔ SDK communication uses ISO 7816 APDUs over NFC:
- **TLV** (Tag-Length-Value) encoding for data serialization (`Common/TLV/`)
- **APDU** command/response pairs (`Common/APDU/`)
- Encryption modes: none → fast → strong (auto-negotiated)

### Architectural Layers

1. **API** — `TangemSdk` public methods
2. **Session** — `CardSession` lifecycle, preflight reads, view delegation
3. **Operations** — Commands (ReadCommand, SignCommand, etc.) and Tasks (ScanTask, AttestationTask)
4. **TLV/APDU** — data encoding with `TlvBuilder`/`TlvEncoder`/`TlvDecoder`, `CommandApdu`/`ResponseApdu`
5. **Transport** — `CardReader`/`NFCReader` (CoreNFC), session management, retry logic
6. **Security** — encryption negotiation, security delay handling, access code caching with biometrics
7. **Crypto** — secp256k1, EdDSA, BLS, BIP32/BIP44 HD wallet derivation

### Operation Categories (in `Operations/`)

Each subdirectory contains related `Command` implementations:
- `Read/` — card reading, `ScanTask` (combined read + attestation)
- `Sign/` — hash signing (single & batch for UTXO chains)
- `Wallet/` — create, purge, import wallets
- `Backup/` — card backup flows
- `Derivation/` — BIP32 HD wallet key derivation
- `Attestation/` — card/wallet key attestation
- `Pins/` — access code & passcode management
- `Files/` — on-card file storage
- `Personalization/` — card initialization (factory)
- `ResetCode/` — PIN reset flows

### Cryptography (`Crypto/`)

- `BIP39/` — mnemonic generation with wordlist resources
- `BIP32/`, `HDWallet/` — hierarchical deterministic key derivation
- `BLS/` — BLS signatures (via vendored `Bls_Signature.xcframework`)
- `secp256k1/` — C library wrapper (separate SPM target `TangemSdk_secp256k1`)

### UI Layer (`UI/`)

- `SessionViewDelegate` protocol — abstraction for UI interactions during NFC sessions
- `DefaultSessionViewDelegate` — built-in implementation using SwiftUI sheets
- Views for scanning, PIN entry, security delay progress

### JSONRPC Support (`Common/JSON/`)

The SDK can be driven via JSONRPC string commands (`startSession(with jsonRequest:)`), enabling cross-platform bridge usage. Requires calling `initializeJSONRPC(networkService:)` first.

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

## Key Conventions

- All public card operations are exposed as methods on `TangemSdk` class, using completion handlers (`CompletionResult<T>`)
- `CompletionResult<T>` is a typealias for `(Result<T, TangemSdkError>) -> Void`
- Operations that are deprecated in favor of the files API are marked with `@available(iOS, deprecated: 100000.0, message: "Use files instead")`
- Localization strings are in `Common/Localization/Resources/` (managed via Lokalise)
- Test fixtures are JSON files in `TangemSdkTests/Jsons/`

## Code Style

**Style Guide:** Follow [Google's Swift Style Guide](https://google.github.io/swift/)

**SwiftUI Previews:** Must be wrapped in `#if DEBUG`/`#endif` and marked with `// MARK: - Previews`:
```swift
// MARK: - Previews

#if DEBUG
struct MyView_Previews: PreviewProvider {
    static var previews: some View {
        MyView()
    }
}
#endif // DEBUG
```

## SPM Target Structure

| Target | Path | Purpose |
|--------|------|---------|
| `TangemSdk` | `TangemSdk/TangemSdk` | Main framework |
| `TangemSdk_secp256k1` | `TangemSdk/TangemSdk/Crypto/secp256k1` | C crypto library |
| `Bls_Signature` | `TangemSdk/TangemSdk/Frameworks/Bls_Signature.xcframework` | BLS binary framework |
| `TangemSdkTests` | `TangemSdk/TangemSdkTests` | Unit tests |

## Documentation

Always use Context7 MCP for fetching library/API documentation, code generation, or configuration steps.

## Xcode MCP Tools

This project has Xcode MCP integration available. **Prefer Xcode MCP tools over shell commands when working with Xcode projects** as they provide direct integration with the IDE.

## Usage Guidelines

1. **Building:** Use `BuildProject` instead of `xcodebuild` CLI for better integration
2. **Diagnostics:** Use `XcodeListNavigatorIssues` to get all project issues before attempting fixes
3. **Testing:** Use `RunSomeTests` for targeted test runs instead of full suite runs
4. **Previews:** Use `RenderPreview` to validate SwiftUI views without running the simulator
5. **Documentation:** Use `DocumentationSearch` to find Apple API documentation and WWDC content

## Git & CI

- **Main branch**: `develop`
- **Feature branches**: e.g., `develop-fw8` (V8 firmware support)
- **Commit message style**: `IOS-XXXXX Description (#PR)` (Jira ticket prefix)
- **CI**: GitHub Actions on `macos-15`, runs `bundle exec fastlane test` on PRs to `develop` and `release/**`
- **Additional workflows**: publish-release, sync-to-public-repo, update-localizations (Lokalise), create-release-branch, check-tag, set-tag, generate-changelog

## Miscellaneous

- DO NOT read, access or modify files at paths specified in the @.cursorignore file
- All commits in this repository must always have a valid GPG signature
