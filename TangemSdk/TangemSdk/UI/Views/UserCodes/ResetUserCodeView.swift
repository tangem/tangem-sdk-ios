//
//  ResetUserCodeView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 26.10.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct ResetUserCodeView: View {
    let title: String
    let cardId: String
    let messageTitle: String
    let messageBody: String
    let completion: ((Bool) -> Void)
    
    @EnvironmentObject var style: TangemSdkStyle
    
    @State private var isLoading: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .center, spacing: 0) {
                UserCodeHeaderView(title: title,
                                   cardId: cardId,
                                   onCancel: onCancel)
                    .padding(.top, 8)
                
                Spacer()
                
                cardsStack(geo.size)
                
                Spacer()
                
                Text(messageTitle)
                    .font(Font.system(size: 28).bold())
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 16)
                
                Text(messageBody)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16))
                
                Spacer()
                
                Button("common_continue".localized, action: onDone)
                    .buttonStyle(RoundedButton(style: style,
                                               isLoading: isLoading))
            }
        }
        .padding([.horizontal, .bottom])
        .onAppear {
            if isLoading {
                isLoading = false
            }
        }
    }
    
    @ViewBuilder
    private func cardsStack(_ size: CGSize) -> some View {
        let topCardWidth = 0.8 * size.width
        let topCardHeight = 0.6 * topCardWidth
        
        let bottomCardWidth = 0.88 * topCardWidth
        let bottomCardHeight = 0.88 * topCardHeight
        
        ZStack {
            BadgedCardView(cardColor: Color(UIColor.systemGray5),
                           starsColor: .gray,
                           name: "Linked card",
                           badgeBackground: .gray.opacity(0.25),
                           badgeForeground: .gray)
                .frame(width: bottomCardWidth, height: bottomCardHeight)
                .offset(y: 0.16 * bottomCardHeight)
            
            BadgedCardView(cardColor: style.colors.tint,
                           starsColor: .white,
                           name: "Current card",
                           badgeBackground: .white.opacity(0.25),
                           badgeForeground: .white)
                .frame(width: topCardWidth, height: topCardHeight)
        }
    }
    
    private func onCancel() {
        completion(false)
    }
    
    private func onDone() {
        completion(true)
    }
}

@available(iOS 13.0, *)
struct ResetUserCodeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            
            ResetUserCodeView(title: "Title",
                              cardId: "0000 1111 2222 3333 444",
                              messageTitle: "Tap the card you want to restore",
                              messageBody: "First, prepare the card for restore process.",
                              completion: {_ in})
            
            ResetUserCodeView(title: "Title",
                              cardId: "0000 1111 2222 3333 444",
                              messageTitle: "Tap the card you want to restore",
                              messageBody: "First, prepare the card for restore process.",
                              completion: {_ in})
                .preferredColorScheme(.dark)
        }
        .environmentObject(TangemSdkStyle())
    }
}
