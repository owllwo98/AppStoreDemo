//
//  LaunchView.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/28/25.
//

import SwiftUI

struct RootView: View {
    @State private var isLaunch: Bool = true
    
    var body: some View {
        Group {
            if isLaunch {
                LaunchView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.linear) {
                                isLaunch = false
                            }
                        }
                    }
            } else {
                AppStoreMainView()
            }
        }
    }
}

struct LaunchView: View {
    var body: some View {
        VStack {
            Text("변정훈")
                .font(.largeTitle)
                .fontWeight(.black)
        }
        .padding()
    }
}

//#Preview {
//    LaunchView()
//}
