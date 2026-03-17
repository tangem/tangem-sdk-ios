//
//  MainTabView.swift
//  TangemSdkExample
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

// MARK: - Main Tab View

struct MainTabView: View {
    @ObservedObject var viewModel: MainTabViewModel

    var body: some View {
        VStack {
            logView
            controlsView
        }
        .padding(.bottom, 8)
        .confirmationDialog("Select wallet", isPresented: $viewModel.showWalletSelection) {
            walletSelectionButtons
        }
    }

    private var logView: some View {
        VStack(spacing: 4) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack {
                        if let image = viewModel.image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                        }

                        Text(viewModel.logText)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Color.clear
                            .frame(height: 0)
                            .id("logBottom")
                    }
                }
                .onChange(of: viewModel.logText) { _ in
                    withAnimation {
                        proxy.scrollTo("logBottom", anchor: .bottom)
                    }
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
                Button("Clear", action: viewModel.clear)
                Button("Copy", action: viewModel.copy)
            }
            .padding(.horizontal, 8)
        }
        .layoutPriority(-1)
    }

    private var controlsView: some View {
        VStack(spacing: 4) {
            additionalView
                .padding(.top, 4)

            Picker("", selection: $viewModel.method) {
                ForEach(MainTabViewModel.Method.allCases, id: \.self) { method in
                    Text(method.rawValue).tag(method)
                }
            }
            .frame(minHeight: 110)
            .labelsHidden()
            .pickerStyle(.wheel)

            Button("Start") { viewModel.start() }
                .buttonStyle(ExampleButton(isLoading: viewModel.isScanning))
                .frame(width: 100)
        }
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private var walletSelectionButtons: some View {
        if let wallets = viewModel.card?.wallets {
            ForEach(wallets, id: \.index) { wallet in
                let publicKeyDescription = wallet.publicKey.map {
                    let hex = $0.hexString
                    return "\(hex.prefix(6))...\(hex.suffix(6))"
                } ?? ""

                Button("(\(wallet.index)) \(publicKeyDescription) (\(wallet.curve.rawValue))") {
                    viewModel.start(walletIndex: wallet.index)
                }
            }
        }

        Button("Cancel", role: .cancel) {
            viewModel.isScanning = false
        }
    }

    // MARK: - Additional Views per Method

    @ViewBuilder
    private var additionalView: some View {
        switch viewModel.method {
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
            Toggle("Is user code recovery allowed", isOn: $viewModel.isUserCodeRecoveryAllowed)
        case .setPinRequired:
            Toggle("Is PIN required", isOn: $viewModel.isPinRequired)
        case .setNDEFDisabled:
            Toggle("Is NDEF disabled", isOn: $viewModel.isNDEFDisabled)
        default:
            EmptyView()
        }
    }

    private var attestView: some View {
        VStack {
            Text("Attestation configuration")
                .font(.headline)
                .bold()

            Picker("", selection: $viewModel.attestationMode) {
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

            TextField("\"m/0/1\"", text: $viewModel.derivationPath)
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

            TextField("\"m/0/1\"", text: $viewModel.derivationPath)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if case .signHashes = viewModel.method {
                Text("Sign hashes count")
                    .font(.headline)
                    .bold()

                TextField("", text: $viewModel.signHashesCount)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
            }
        }
        .orangeBorder()
    }

    private var curveSelector: some View {
        Group {
            if let supportedCurves = viewModel.card?.supportedCurves {
                Picker("", selection: $viewModel.curve) {
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
            TextField("Optional mnemonic", text: $viewModel.mnemonicString)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)

            TextField("Optional passphrase", text: $viewModel.passphrase)
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

            TextEditor(text: $viewModel.editorData)
                .frame(height: 100)

            Button("Paste json", action: viewModel.pasteEditor)
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .orangeBorder()
        .onAppear(perform: viewModel.onAppear)
    }

    private var persoJsonEditorView: some View {
        VStack {
            Text("JSON editor")
                .font(.headline)
                .bold()

            TextEditor(text: $viewModel.editorData)
                .frame(height: 100)

            HStack {
                Button("Paste json", action: viewModel.pasteEditor)
                Button("Reset to defaults", action: viewModel.resetPersonalizationConfig)
            }
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .orangeBorder()
        .onAppear(perform: viewModel.onAppear)
    }
}

#Preview {
    NavigationStack {
        MainTabView(viewModel: MainTabViewModel())
    }
}
