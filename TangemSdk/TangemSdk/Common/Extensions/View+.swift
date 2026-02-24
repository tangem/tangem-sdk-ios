//
//  View+.swift
//  TangemSdk
//
//  Created by GuitarKitty on 20.02.2026.
//

import SwiftUI

extension View {
    /// Adds bottom padding only on devices that have zero bottom safe area (e.g. devices with a home button).
    /// 6 points by default.
    func bottomPaddingIfZeroSafeArea(_ padding: CGFloat = 6) -> some View {
        let bottomInset = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0

        return self.padding(.bottom, bottomInset == 0 ? padding : 0)
    }
}
