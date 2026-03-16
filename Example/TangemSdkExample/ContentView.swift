//
//  ContentView.swift
//  TangemSDKExample
//
//  Created by Alexander Osokin on 04.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSdk

// MARK: - Orange Border Modifier

private struct OrangeBorderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange, lineWidth: 2))
    }
}

private extension View {
    func orangeBorder() -> some View {
        modifier(OrangeBorderModifier())
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        NavigationStack {
            TabView {
                MainTab()
                    .tabItem {
                        Label("Main", systemImage: "house")
                    }

                BackupView(viewModel: model.backupViewModel)
                    .onAppear { model.setupBackup() }
                    .tabItem {
                        Label("Backup", systemImage: "doc.on.doc")
                    }

                ResetPinView(viewModel: model.resetPinViewModel)
                    .onAppear { model.setupResetPin() }
                    .tabItem {
                        Label("Reset Pin", systemImage: "arrow.counterclockwise")
                    }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        UIApplication.shared.endEditing()
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                }
            }
            .navigationDestination(isPresented: $model.showSettings) {
                model.makeSettingsDestination()
            }
        }
    }
}

// MARK: - Main Tab

struct MainTab: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack {
            logView
            controlsView
        }
        .padding(.bottom, 8)
        .navigationTitle("SDK")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: model.onSettings) {
                    Image(systemName: "gear")
                }
            }
        }
        .confirmationDialog("Select wallet", isPresented: $model.showWalletSelection) {
            walletSelectionButtons
        }
    }

    private var logView: some View {
        VStack(spacing: 4) {
            ScrollView {
                VStack {
                    if let image = model.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                    }

                    Text(model.logText)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 14)
            .clipped()
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.orange, lineWidth: 2)
                    .padding(.horizontal, 8)
            )

            HStack(spacing: 16) {
                Button("Clear", action: model.clear)
                Button("Copy", action: model.copy)
            }
            .padding(.horizontal, 8)
        }
        .layoutPriority(-1)
    }

    private var controlsView: some View {
        VStack(spacing: 4) {
            additionalView
                .padding(.top, 4)

            Picker("", selection: $model.method) {
                ForEach(AppModel.Method.allCases, id: \.self) { method in
                    Text(method.rawValue).tag(method)
                }
            }
            .frame(minHeight: 110)
            .labelsHidden()
            .pickerStyle(.wheel)

            Button("Start") { model.start() }
                .buttonStyle(ExampleButton(isLoading: model.isScanning))
                .frame(width: 100)
        }
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private var walletSelectionButtons: some View {
        if let wallets = model.card?.wallets {
            ForEach(wallets, id: \.index) { wallet in
                let publicKeyDescription = wallet.publicKey.map {
                    let hex = $0.hexString
                    return "\(hex.prefix(6))...\(hex.suffix(6))"
                } ?? ""

                Button("(\(wallet.index)) \(publicKeyDescription) (\(wallet.curve.rawValue))") {
                    model.start(walletIndex: wallet.index)
                }
            }
        }

        Button("Cancel", role: .cancel) {
            model.isScanning = false
        }
    }

    // MARK: - Additional Views per Method

    @ViewBuilder
    private var additionalView: some View {
        switch model.method {
        case .attest:
            attestView
        case .attestWallet:
            attestWalletView
        case .createWallet:
            createWalletView
        case .importWallet:
            importWalletView
        case .signHash, .signHashes, .derivePublicKey, .readMasterSecret:
            hdPathView
        case .jsonrpc:
            jsonEditorView
        case .personalize, .personalizeV8:
            persoJsonEditorView
        case .importMasterSecret:
            importMasterSecretView
        case .setUserCodeRecoveryAllowed:
            Toggle("Is user code recovery allowed", isOn: $model.isUserCodeRecoveryAllowed)
        case .setPinRequired:
            Toggle("Is PIN required", isOn: $model.isPinRequired)
        case .setNDEFDisabled:
            Toggle("Is NDEF disabled", isOn: $model.isNDEFDisabled)
        default:
            EmptyView()
        }
    }

    private var attestView: some View {
        VStack {
            Text("Attestation configuration")
                .font(.headline)
                .bold()

            Picker("", selection: $model.attestationMode) {
                ForEach(AttestationTask.Mode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .orangeBorder()
    }

    private var attestWalletView: some View {
        VStack {
            Text("Wallet Attestation config")
                .font(.headline)
                .bold()

            TextField("\"m/0/1\"", text: $model.derivationPath)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .orangeBorder()
    }

    private var createWalletView: some View {
        VStack {
            Text("Create wallet configuration")
                .font(.headline)
                .bold()

            curveSelector
        }
        .orangeBorder()
    }

    private var importWalletView: some View {
        VStack {
            Text("Import wallet configuration")
                .font(.headline)
                .bold()

            curveSelector

            mnemonicFields
        }
        .orangeBorder()
    }

    private var hdPathView: some View {
        VStack {
            Text("Hd path")
                .font(.headline)
                .bold()

            TextField("\"m/0/1\"", text: $model.derivationPath)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if case .signHashes = model.method {
                Text("Sign hashes count")
                    .font(.headline)
                    .bold()

                TextField("", text: $model.signHashesCount)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
            }
        }
        .orangeBorder()
    }

    
    private var curveSelector: some View {
        Group {
            if let supportedCurves = model.card?.supportedCurves {
                Picker("", selection: $model.curve) {
                    ForEach(supportedCurves, id: \.self) { curve in
                        Text(curve.rawValue).tag(curve)
                    }
                }
                .pickerStyle(.wheel)
            }
        }
    }

    private var mnemonicFields: some View {
        Group {
            TextField("Optional mnemonic", text: $model.mnemonicString)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)

            TextField("Optional passphrase", text: $model.passphrase)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
        }
    }

    private var importMasterSecretView: some View {
        VStack {
            Text("Import master secret configuration")
                .font(.headline)
                .bold()

            mnemonicFields
        }
        .orangeBorder()
    }

    private var jsonEditorView: some View {
        VStack {
            Text("JSON editor")
                .font(.headline)
                .bold()

            TextEditor(text: $model.editorData)
                .frame(height: 100)

            Button("Paste json", action: model.pasteEditor)
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .orangeBorder()
        .onAppear(perform: model.onAppear)
    }

    private var persoJsonEditorView: some View {
        VStack {
            Text("JSON editor")
                .font(.headline)
                .bold()

            TextEditor(text: $model.editorData)
                .frame(height: 100)

            HStack {
                Button("Paste json", action: model.pasteEditor)
                Button("Reset to defaults", action: model.resetPersonalizationConfig)
            }
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .orangeBorder()
        .onAppear(perform: model.onAppear)
    }
}


#Preview {
    ContentView()
        .environmentObject(AppModel())
}
