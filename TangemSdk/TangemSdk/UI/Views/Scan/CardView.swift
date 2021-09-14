//
//  CardView.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct CardView: View {
    @EnvironmentObject var style: TangemSdkStyle
    
    var body: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(style.colors.cardColor)
    }
}

@available(iOS 13.0, *)
struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CardView()
                .frame(width: 300, height: 200)
            CardView()
                .preferredColorScheme(.dark)
                .frame(width: 300, height: 200)
        }
        .environmentObject(TangemSdkStyle())
    }
}
