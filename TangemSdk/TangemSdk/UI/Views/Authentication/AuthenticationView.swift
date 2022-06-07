//
//  AuthenticationView.swift
//  TangemSdk
//
//  Created by Andrey Chukavin on 07.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct AuthenticationView: View {
    var body: some View {
        VStack {
            VStack {
                Text("Please authenticate with Face ID")
                    .font(.system(size: 20, weight: .bold))
                    
                Image(systemName: "faceid")
                    .font(.system(size: 40))
            }
            .padding(.top, 50)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .edgesIgnoringSafeArea(.bottom)
    }
}

@available(iOS 13.0, *)
struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
