//
//  SecurityNoticeView.swift
//  TangemSdk
//
//  Created by Viacheslav Efimenko on 11.02.2026.
//

import SwiftUI

struct SecurityNoticeView: View {
    @EnvironmentObject var style: TangemSdkStyle

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color(UIColor.systemYellow))
                .font(.system(size: 16, weight: .semibold))
                .padding(.top, 2)

            Text("tangem_never_pregenerate_code_alert".localized)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.init(top: 12, leading: 14, bottom: 12, trailing: 32))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: UIColor.LightPalette.warningBackground).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
