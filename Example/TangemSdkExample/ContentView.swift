//
//  ContentView.swift
//  TangemSDKExample
//
//  Created by Alexander Osokin on 04.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSdk

// MARK: - Content View

struct ContentView: View {
    @StateObject private var mainViewModel = MainTabViewModel()
    @StateObject private var backupViewModel = BackupViewModel()
    @StateObject private var resetPinViewModel = ResetPinViewModel()

    @State private var selectedTab: Tab = .main
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                MainTabView(viewModel: mainViewModel)
                    .tag(Tab.main)
                    .tabItem { Label("Main", systemImage: "house") }
                    .keyboardDismissToolbarWorkaround()

                BackupView(viewModel: backupViewModel)
                    .onAppear { setupBackup() }
                    .tag(Tab.backup)
                    .tabItem { Label("Backup", systemImage: "doc.on.doc") }
                    .keyboardDismissToolbarWorkaround()

                ResetPinView(viewModel: resetPinViewModel)
                    .onAppear { setupResetPin() }
                    .tag(Tab.resetCodes)
                    .tabItem { Label("Reset Codes", systemImage: "arrow.counterclockwise") }
                    .keyboardDismissToolbarWorkaround()
            }
            .navigationTitle(selectedTab.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        UIApplication.shared.endEditing()
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                }
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    private func setupBackup() {
        guard !backupViewModel.isSetUp else { return }

        let sdk = mainViewModel.configuredSdk
        let service = BackupService(sdk: sdk, networkService: .init(session: .shared, additionalHeaders: [:]))
        backupViewModel.setup(backupService: service)
    }

    private func setupResetPin() {
        guard !resetPinViewModel.isSetUp else { return }

        let sdk = mainViewModel.configuredSdk
        let service = ResetPinService(config: sdk.config)
        resetPinViewModel.setup(resetPinService: service)
    }
}

// MARK: - Tab

extension ContentView {
    enum Tab {
        case main
        case backup
        case resetCodes

        var title: String {
            switch self {
            case .main: "SDK"
            case .backup: "Backup"
            case .resetCodes: "Reset Codes"
            }
        }
    }
}

// MARK: - iOS 26 Keyboard Toolbar Workaround

/// Workaround for iOS 26.3 bug where keyboard toolbar on NavigationStack
/// doesn't propagate to TabView children. Applied per-tab with availability check.
private struct KeyboardDismissToolbarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar {
                if #available(iOS 26.0, *) {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button {
                            UIApplication.shared.endEditing()
                        } label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                        }
                    }
                }
            }
    }
}

private extension View {
    func keyboardDismissToolbarWorkaround() -> some View {
        modifier(KeyboardDismissToolbarModifier())
    }
}

#Preview {
    ContentView()
}
